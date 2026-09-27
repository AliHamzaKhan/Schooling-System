"""F01.6 aggregate boundaries, report permissions and source reconciliation."""
import csv
import io
from datetime import date
from uuid import UUID, uuid4

import pytest
from sqlalchemy import delete, update

from app.models.academic import SchoolClass, Section, StudentEnrollment, Subject
from app.models.associations import user_roles
from app.models.attendance import AttendanceRecord
from app.models.examination import Exam, ExamCategory, ExamResult
from app.models.fees import FeeStructure, Invoice, Payment
from app.models.homework import Assignment
from app.models.role import Role, RolePermission
from app.models.school import AcademicSession
from tests.conftest import API
from tests.test_broadcast_isolation import another_school
from tests.test_direct_message_boundaries import family as _family_fixture
from tests.utils import create_user, enroll, login, make_academics

family = _family_fixture
ENDPOINTS = ['overview', 'attendance', 'academic', 'finance', 'enrollment', 'attendance/export']


def base(school):
    return f"{API}/schools/{school['id']}"


@pytest.mark.parametrize('role', ['teacher', 'student', 'guardian', 'driver'])
async def test_default_roles_cannot_read_schoolwide_aggregates(client, school, role):
    user = await create_user(client, school['id'], school['hm'], role)
    headers = await login(client, user['email'], user['password'])
    for endpoint in ENDPOINTS:
        r = await client.get(base(school) + '/reports/' + endpoint, headers=headers)
        assert r.status_code == 403, r.text
        assert 'no-store' in r.headers['cache-control']


async def test_report_view_export_revocation_and_toggle_for_custom_staff(client, school, family):
    async with family['sessions']() as db, db.begin():
        role = Role(school_id=UUID(school['id']), code='report_reviewer', name='Report reviewer',
                    permissions=[RolePermission(module='reports', can_view=True)])
        db.add(role)
        await db.flush()
        role_id = role.id
        await db.execute(delete(user_roles).where(user_roles.c.user_id == UUID(family['teacher']['id'])))
        await db.execute(user_roles.insert().values(user_id=UUID(family['teacher']['id']), role_id=role_id))
    headers = family['teacher']['headers']
    for endpoint in ENDPOINTS:
        r = await client.get(base(school) + '/reports/' + endpoint, headers=headers)
        assert r.status_code == (403 if endpoint.endswith('export') else 200), r.text
    async with family['sessions']() as db, db.begin():
        await db.execute(update(RolePermission).where(RolePermission.role_id == role_id).values(can_view=False, can_export=True))
    assert (await client.get(base(school) + '/reports/attendance', headers=headers)).status_code == 403
    # Existing export is an independent action, not a grant inferred from view.
    assert (await client.get(base(school) + '/reports/attendance/export', headers=headers)).status_code == 200
    r = await client.put(base(school) + '/modules', headers=school['sa'], json={'toggles': [{'module': 'reports', 'enabled': False}]})
    assert r.status_code == 200
    for endpoint in ENDPOINTS:
        for h in [headers, school['hm']]:
            assert (await client.get(base(school) + '/reports/' + endpoint, headers=h)).status_code == 403
        assert (await client.get(base(school) + '/reports/' + endpoint, headers=school['sa'])).status_code == 200


async def test_other_school_paths_and_report_filters_fail_closed(client, school, family):
    foreign = await another_school(client, school['sa'])
    ac = await make_academics(client, foreign, school['sa'])
    for endpoint in ENDPOINTS:
        r = await client.get(f'{API}/schools/{foreign}/reports/{endpoint}', headers=school['hm'])
        assert r.status_code == 403 and 'no-store' in r.headers['cache-control']
    for endpoint in ['attendance', 'attendance/export']:
        path = base(school) + '/reports/' + endpoint
        for section in [ac['section_id'], str(uuid4())]:
            r = await client.get(path, headers=school['hm'], params={'section_id': section})
            assert r.status_code == 404, r.text
        assert (await client.get(path, headers=school['hm'], params={'section_id': 'bad'})).status_code == 422
        assert (await client.get(path, headers=school['hm'], params={'date_from': '2026-09-22', 'date_to': '2026-09-01'})).status_code == 400


async def test_attendance_json_csv_and_register_reconcile_without_foreign_rows_or_formula_labels(client, school, family):
    foreign = await another_school(client, school['sa'])
    ac = await make_academics(client, foreign, school['sa'])
    foreign_student = await create_user(client, foreign, school['sa'], 'student')
    common = dict(school_id=UUID(school['id']), section_id=UUID(family['academic']['section_id']),
                  student_id=UUID(family['student']['id']), attendance_date=date(2026, 9, 22), status='present')
    async with family['sessions']() as db, db.begin():
        db.add(AttendanceRecord(**common))
        db.add(AttendanceRecord(**(common | {'attendance_date': date(2026, 9, 23), 'status': 'late'})))
        db.add(AttendanceRecord(**(common | {'attendance_date': date(2026, 9, 24), 'status': '=HYPERLINK("secret")'})))
        db.add(AttendanceRecord(**(common | {'student_id': UUID(foreign_student['id'])})))
        db.add(AttendanceRecord(**(common | {'subject_id': UUID(ac['subject_id'])})))
        db.add(AttendanceRecord(**(common | {'attendance_date': date(2026, 9, 25), 'section_id': UUID(ac['section_id'])})))
        db.add(AttendanceRecord(**(common | {'attendance_date': date(2026, 9, 26), 'school_id': UUID(foreign)})))
    params = {'section_id': family['academic']['section_id'], 'date_from': '2026-09-22', 'date_to': '2026-09-26'}
    r = await client.get(base(school) + '/reports/attendance', headers=school['hm'], params=params)
    assert r.status_code == 200, r.text
    assert r.json()['total_records'] == 2 and r.json()['present_rate'] == 100
    export = await client.get(base(school) + '/reports/attendance/export', headers=school['hm'], params=params)
    assert export.status_code == 200 and 'no-store' in export.headers['cache-control']
    rows = dict(csv.reader(io.StringIO(export.text)))
    assert rows['total'] == '2' and rows['present'] == '1' and rows['late'] == '1'
    assert 'HYPERLINK' not in export.text
    for day in ['2026-09-22', '2026-09-23']:
        source = await client.get(base(school) + '/attendance', headers=school['hm'],
                                  params={'section_id': params['section_id'], 'attendance_date': day})
        assert source.status_code == 200 and len(source.json()) == 1
    limited = await client.get(base(school) + '/reports/attendance', headers=school['hm'],
                               params=params | {'date_to': '2026-09-22'})
    assert limited.json()['total_records'] == 1


async def test_overview_enrollment_nested_ownership_and_distinct_school_students(client, school, family):
    foreign = await another_school(client, school['sa'])
    foreign_ac = await make_academics(client, foreign, school['sa'])
    foreign_student = await create_user(client, foreign, school['sa'], 'student')
    sid, ac = UUID(school['id']), family['academic']
    # A valid second class includes the same student. It counts once per class,
    # and once overall, rather than adding the class totals.
    r = await client.post(base(school) + '/academic/classes', headers=school['hm'], json={'name': 'Second'})
    second_class = r.json()['id']
    r = await client.post(base(school) + f'/academic/classes/{second_class}/sections', headers=school['hm'], json={'name': 'B'})
    second_section = r.json()['id']
    await enroll(client, school['id'], school['hm'], second_section, family['student']['id'])
    async with family['sessions']() as db, db.begin():
        session = AcademicSession(school_id=UUID(foreign), name='Foreign session')
        db.add(session)
        await db.flush()
        cls = SchoolClass(school_id=sid, name='Invalid session class', session_id=session.id)
        db.add(cls)
        await db.flush()
        db.add(Section(school_id=sid, class_id=cls.id, name='Bad class'))
        db.add(Section(school_id=UUID(foreign), class_id=UUID(ac['class_id']), name='Foreign section'))
        db.add(Subject(school_id=sid, class_id=UUID(foreign_ac['class_id']), code='BAD', name='Bad subject'))
        db.add(StudentEnrollment(school_id=sid, section_id=UUID(ac['section_id']), student_id=UUID(foreign_student['id']), status='active'))
        db.add(StudentEnrollment(school_id=sid, section_id=UUID(ac['section_id']), student_id=UUID(family['other']['id']), status='active', session_id=session.id))
        db.add(StudentEnrollment(school_id=UUID(foreign), section_id=UUID(second_section), student_id=UUID(family['other']['id']), status='active'))
    r = await client.get(base(school) + '/reports/enrollment', headers=school['hm'])
    assert r.status_code == 200, r.text
    assert r.json()['total_students'] == 1
    assert len(r.json()['classes']) == 2
    assert all(c['students'] == 1 and c['sections'] == 1 for c in r.json()['classes'])
    r = await client.get(base(school) + '/reports/overview', headers=school['hm'])
    assert r.status_code == 200, r.text
    assert (r.json()['classes'], r.json()['sections'], r.json()['subjects']) == (2, 2, 1)
    assert r.json()['students'] == 2  # registered users, not enrollment total


async def test_student_report_excludes_assignments_from_foreign_session_enrollment(client, school, family):
    """The student report shares enrollment eligibility with aggregate reports."""
    foreign = await another_school(client, school['sa'])
    sid, ac = UUID(school['id']), family['academic']
    root = base(school)
    created = await client.post(
        root + f"/academic/classes/{ac['class_id']}/sections",
        headers=school['hm'],
        json={'name': 'Foreign-session enrollment'},
    )
    assert created.status_code == 201, created.text
    section_id = UUID(created.json()['id'])
    async with family['sessions']() as db, db.begin():
        session = AcademicSession(school_id=UUID(foreign), name='Foreign session')
        db.add(session)
        await db.flush()
        db.add(StudentEnrollment(
            school_id=sid,
            section_id=section_id,
            student_id=UUID(family['student']['id']),
            session_id=session.id,
            status='active',
        ))
        db.add(Assignment(
            school_id=sid,
            section_id=section_id,
            subject_id=UUID(ac['subject_id']),
            title='Must not appear',
            assigned_on=date(2026, 9, 22),
            due_date=date(2026, 9, 29),
        ))
    report = await client.get(
        root + f"/reports/students/{family['student']['id']}", headers=school['hm']
    )
    assert report.status_code == 200, report.text
    assert report.json()['assignments_total'] == 0


async def test_academic_summary_excludes_foreign_results_students_and_drafts(client, school, family):
    foreign = await another_school(client, school['sa'])
    foreign_ac = await make_academics(client, foreign, school['sa'])
    foreign_student = await create_user(client, foreign, school['sa'], 'student')
    sid = UUID(school['id'])
    async with family['sessions']() as db, db.begin():
        exam = Exam(school_id=sid, class_id=UUID(family['academic']['class_id']), name='Valid exam')
        bad = Exam(school_id=sid, class_id=UUID(foreign_ac['class_id']), name='Foreign class exam')
        db.add_all([exam, bad])
        await db.flush()
        common = dict(school_id=sid, exam_id=exam.id, student_id=UUID(family['student']['id']),
                      total_marks=80, max_total=100, percentage=80, grade='A', status='pass', published=True)
        db.add(ExamResult(**common))
        db.add(ExamResult(**(common | {'student_id': UUID(foreign_student['id']), 'percentage': 99})))
        db.add(ExamResult(**(common | {'student_id': UUID(family['other']['id']), 'published': False})))
        db.add(ExamResult(**(common | {'student_id': UUID(family['teacher']['id'])})))
        db.add(ExamResult(**(common | {'exam_id': bad.id})))
    r = await client.get(base(school) + '/reports/academic', headers=school['hm'])
    assert r.status_code == 200, r.text
    assert len(r.json()['exams']) == 1
    assert r.json()['exams'][0]['results'] == 1
    assert r.json()['exams'][0]['average_percentage'] == 80
    async with family['sessions']() as db, db.begin():
        await db.execute(update(ExamResult).where(ExamResult.exam_id == exam.id).values(school_id=UUID(foreign)))
    assert (await client.get(base(school) + '/reports/academic', headers=school['hm'])).json()['exams'] == []


async def test_finance_uses_tenant_ledger_and_ignores_invalid_invoice_links_without_writes(client, school, family):
    foreign = await another_school(client, school['sa'])
    foreign_student = await create_user(client, foreign, school['sa'], 'student')
    sid = UUID(school['id'])
    async with family['sessions']() as db, db.begin():
        session = AcademicSession(school_id=UUID(foreign), name='Foreign session')
        structure = FeeStructure(school_id=UUID(foreign), name='Foreign structure', amount=999)
        db.add_all([session, structure])
        await db.flush()
        common = dict(school_id=sid, student_id=UUID(family['student']['id']), title='Fee', amount=100,
                      amount_paid=99, status='paid', due_date=date(2020, 1, 1))
        invoice = Invoice(**common)
        invalid = [Invoice(**(common | change)) for change in [
            {'student_id': UUID(foreign_student['id'])}, {'student_id': UUID(family['teacher']['id'])},
            {'session_id': session.id}, {'fee_structure_id': structure.id}, {'school_id': UUID(foreign)}]]
        db.add_all([invoice, *invalid])
        await db.flush()
        db.add(Payment(school_id=sid, invoice_id=invoice.id, amount=40, method='cash', paid_on=date(2026, 9, 22)))
        db.add(Payment(school_id=UUID(foreign), invoice_id=invoice.id, amount=50, method='cash', paid_on=date(2026, 9, 22)))
        for bad in invalid:
            db.add(Payment(school_id=sid, invoice_id=bad.id, amount=90, method='cash', paid_on=date(2026, 9, 22)))
        invoice_id = invoice.id
    for path in ['/fees/report', '/reports/finance']:
        r = await client.get(base(school) + path, headers=school['hm'])
        assert r.status_code == 200, r.text
        result = r.json()
        assert (result['total_invoices'], result['total_billed'], result['total_collected'], result['total_outstanding'], result['overdue_count']) == (1, 100, 40, 60, 1)
        if path == '/fees/report':
            assert result['status_counts']['partial'] == 1
    async with family['sessions']() as db:
        row = await db.get(Invoice, invoice_id)
        assert row.amount_paid == 99 and row.status == 'paid'


async def test_plan_downgrade_revokes_reports_despite_enabled_toggle(client, school):
    assert (await client.get(base(school) + '/reports/overview', headers=school['hm'])).status_code == 200
    r = await client.post(base(school) + '/subscription', headers=school['sa'], json={'plan_code': 'standard'})
    assert r.status_code in [200, 201], r.text
    await client.put(base(school) + '/modules', headers=school['sa'], json={'toggles': [{'module': 'reports', 'enabled': True}]})
    for endpoint in ENDPOINTS:
        assert (await client.get(base(school) + '/reports/' + endpoint, headers=school['hm'])).status_code == 403


@pytest.mark.parametrize('reference', ['session', 'category'])
async def test_academic_summary_rejects_foreign_exam_metadata(client, school, family, reference):
    foreign = await another_school(client, school['sa'])
    async with family['sessions']() as db, db.begin():
        target = (AcademicSession(school_id=UUID(foreign), name='Foreign session') if reference == 'session'
                  else ExamCategory(school_id=UUID(foreign), name='Foreign category'))
        db.add(target)
        await db.flush()
        exam = Exam(school_id=UUID(school['id']), class_id=UUID(family['academic']['class_id']),
                    name='Invalid linked exam', **{reference + '_id': target.id})
        db.add(exam)
        await db.flush()
        db.add(ExamResult(school_id=UUID(school['id']), exam_id=exam.id, student_id=UUID(family['student']['id']),
                          total_marks=80, max_total=100, percentage=80, grade='A', status='pass', published=True))
    r = await client.get(base(school) + '/reports/academic', headers=school['hm'])
    assert r.status_code == 200 and r.json()['exams'] == [], r.text


@pytest.mark.parametrize('reference', ['session', 'class'])
async def test_finance_filters_local_structure_with_foreign_parent(client, school, family, reference):
    foreign = await another_school(client, school['sa'])
    async with family['sessions']() as db, db.begin():
        target = (AcademicSession(school_id=UUID(foreign), name='Foreign session') if reference == 'session'
                  else SchoolClass(school_id=UUID(foreign), name='Foreign class'))
        db.add(target)
        await db.flush()
        structure = FeeStructure(school_id=UUID(school['id']), name='Invalid structure', amount=100,
                                 **{reference + '_id': target.id})
        db.add(structure)
        await db.flush()
        db.add(Invoice(school_id=UUID(school['id']), student_id=UUID(family['student']['id']),
                       fee_structure_id=structure.id, title='Invalid', amount=100, due_date=date(2020, 1, 1)))
    for path in ['/reports/finance', '/fees/report']:
        r = await client.get(base(school) + path, headers=school['hm'])
        assert r.status_code == 200 and r.json()['total_invoices'] == 0, r.text
        assert 'no-store' in r.headers['cache-control']


async def test_finance_valid_payment_reconciles_receipt_and_both_reports(client, school, family):
    response = await client.post(base(school) + '/fees/invoices', headers=school['hm'], json={
        'student_id': family['student']['id'], 'title': 'Term', 'amount': 100, 'due_date': '2020-01-01'})
    assert response.status_code == 201, response.text
    invoice_id = response.json()['id']
    r = await client.post(base(school) + f'/fees/invoices/{invoice_id}/payments', headers=school['hm'],
                         json={'amount': 100, 'method': 'cash', 'paid_on': '2026-09-22'})
    assert r.status_code == 201, r.text
    receipt = await client.get(base(school) + f'/fees/invoices/{invoice_id}/receipt', headers=school['hm'])
    for path in ['/fees/report', '/reports/finance']:
        r = await client.get(base(school) + path, headers=school['hm'])
        assert r.status_code == 200, r.text
        assert r.json()['total_collected'] == receipt.json()['total_paid'] == 100
        assert r.json()['total_outstanding'] == 0 and r.json()['overdue_count'] == 0
    assert (await client.get(base(school) + '/fees/report', headers=family['guardian']['headers'])).status_code == 403
