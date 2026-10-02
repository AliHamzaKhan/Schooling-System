from scripts.audit_private_assets import classify_reference, report


SCHOOL = "a5e0b9f7-9fa2-43cd-b77a-d3489ab84930"
OWNER = "97b48fb8-92e3-49d7-a2bd-20fd0d252ec8"


def classify(source, reference, owner=None):
    return classify_reference(
        source=source, record_id="record", school_id=SCHOOL, owner_id=owner,
        reference=reference, public_origin="https://api.example.test",
    )


def test_private_asset_inventory_classifies_current_and_legacy_attachments():
    current = classify(
        "document", f"https://api.example.test/media/private/documents/{SCHOOL}/{OWNER}/file.pdf", OWNER,
    )
    legacy = classify("submission", f"/media/submissions/{SCHOOL}/old.pdf", OWNER)
    assert (current.state, current.target_visibility) == ("managed_private", "private")
    assert (legacy.state, legacy.target_visibility) == ("legacy_record_path", "private")


def test_private_asset_inventory_flags_misowned_and_unsafe_references():
    misowned = classify("document", f"/media/private/documents/{SCHOOL}/other/file.pdf", OWNER)
    external = classify("submission", "https://files.example.test/attachment.pdf", OWNER)
    invalid = classify("document", f"/media/documents/{SCHOOL}/old.pdf?ticket=leak", OWNER)
    assert (misowned.state, misowned.target_visibility) == ("misowned_or_unrecognized_local", "blocked")
    assert (external.state, external.target_visibility) == ("external_reference", "review")
    assert (invalid.state, invalid.target_visibility) == ("invalid_reference", "blocked")


def test_private_asset_inventory_classifies_public_compatibility_and_policy_sources():
    avatar = classify("avatar", f"/media/avatars/{SCHOOL}/photo.png")
    course = classify("course_cover", "https://cdn.example.test/cover.jpg")
    assert (avatar.state, avatar.target_visibility) == ("school_members_path", "school_members")
    assert (course.state, course.target_visibility) == ("external_reference", "review")


def test_private_asset_inventory_report_redacts_reference_values():
    finding = classify("document", f"/media/private/documents/{SCHOOL}/{OWNER}/passport.pdf", OWNER)
    result = report([finding], include_details=True)
    assert result["read_only"] is True
    assert result["summary"][0]["count"] == 1
    assert "passport.pdf" not in str(result)
    assert result["details"][0]["record_id"] == "record"
