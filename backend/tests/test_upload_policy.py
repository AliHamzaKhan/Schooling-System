from unittest.mock import AsyncMock, patch


async def test_upload_accepts_allowlisted_signatures_and_normalizes_metadata(client, school):
    response = await client.post(
        f"/api/v1/schools/{school['id']}/uploads",
        headers=school["hm"],
        data={"folder": "documents"},
        files={"file": ("certificate.exe", b"%PDF-safe", "application/x-msdownload")},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["content_type"] == "application/pdf"
    assert body["filename"].endswith(".pdf")
    assert body["url"].endswith(".pdf")


async def test_upload_rejects_unknown_folder_and_unrecognized_private_content(client, school):
    endpoint = f"/api/v1/schools/{school['id']}/uploads"
    with patch("app.modules.uploads.router.get_storage") as storage:
        storage.return_value.save = AsyncMock()
        unknown = await client.post(
            endpoint, headers=school["hm"], data={"folder": "misc"},
            files={"file": ("anything.pdf", b"%PDF-safe", "application/pdf")},
        )
        unsafe = await client.post(
            endpoint, headers=school["hm"], data={"folder": "documents"},
            files={"file": ("program.pdf", b"MZ-not-a-document", "application/pdf")},
        )
        assert unknown.status_code == 400, unknown.text
        assert unsafe.status_code == 400, unsafe.text
        storage.return_value.save.assert_not_awaited()


async def test_public_upload_uses_signature_not_caller_content_type(client, school):
    response = await client.post(
        f"/api/v1/schools/{school['id']}/uploads",
        headers=school["hm"],
        data={"folder": "uniform"},
        files={"file": ("uniform.txt", b"\x89PNG\r\n\x1a\nimage", "text/plain")},
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["content_type"] == "image/png"
    assert body["filename"].endswith(".png")
    public = await client.get(body["url"], headers=school["hm"])
    assert public.status_code == 200
    assert public.headers["content-type"] == "image/png"
