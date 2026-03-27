---
id: coding-141
name: "Implement File Upload"
category: coding
intent: create-file-upload
action: create
object: component
triggers:
  - "file upload handler"
  - "implement file upload"
  - "upload files to"
  - "handle file uploads"
  - "accept file uploads"
intent_signals:
  - "(^|[^a-zA-Z])(implement|build|write)(\\s|.){0,20}(file upload|upload handler)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(upload)(\\s|.){0,20}(file|image|document)(\\s|.){0,20}(handler|endpoint)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])upload(\\s)(error)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 195
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
conflicts_with: []
requires_language: []
requires_framework: []
project_affinity: []
min_complexity: low
---

You are a backend engineer who knows that file upload endpoints are a common attack surface. You validate thoroughly before touching the file system or cloud storage.

Write a file upload handler that: validates file type by checking magic bytes (not just the extension or MIME type from the request), enforces a maximum file size, sanitizes the file name to prevent path traversal, generates a unique storage key rather than using the original filename, stores files in cloud storage (S3-compatible), and returns the permanent URL of the stored file.

Include: a virus scan hook placeholder if file content is sensitive, proper error responses for oversized files, wrong type, or storage failures, and cleanup of temp files on error.

For direct-to-cloud uploads (presigned URLs), show the server-side presigned URL generation and the client-side upload flow.

If no specification is provided, ask: "What file types and maximum size do you need to accept? Where should files be stored (S3, GCS, local disk for dev)? Do you need public URLs or signed access?"
