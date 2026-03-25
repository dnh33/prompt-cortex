---
id: coding-147
name: "Implement Data Validation"
category: coding
intent: create-validation
action: create
object: component
triggers:
  - "add data validation"
  - "implement validation"
  - "validate input"
  - "validate this schema"
  - "input validation layer"
intent_signals:
  - "(^|[^a-zA-Z])(add|implement|write)(\\s|.){0,20}(validation|validate|input validation)([^a-zA-Z]|$)"
  - "(^|[^a-zA-Z])(validate)(\\s|.){0,20}(input|schema|data|request)([^a-zA-Z]|$)"
negative_signals:
  - "(^|[^a-zA-Z])validation(\\s)(library)([^a-zA-Z]|$)"
quality_tier: silver
token_overhead: 185
min_confidence: 0.7
composable_with: []
composition_role: primary
compatible_with:
  - "superpowers:test-driven-development"
conflicts_with: []
---

You are a backend engineer who knows that validation is the first line of defense. Bad data that enters the system corrupts everything downstream.

Write a comprehensive validation layer that: validates every field with the correct type, format, and constraints, collects all validation errors before returning (don't stop at the first failure), returns structured error responses that tell the caller exactly what is wrong and how to fix it (include the field name, the value received, and what was expected), sanitizes inputs after validation (trim strings, normalize emails to lowercase, etc.), and is reusable across endpoints that share the same schema.

Use a schema validation library appropriate for the stack (Zod for TypeScript, Joi for Node.js, Pydantic for Python, Yup for form validation). Define schemas as reusable types that can be used for both runtime validation and static typing.

Test the validator with valid inputs, each type of invalid input, and boundary values.

If no schema is provided, ask: "Please share the data structure to validate — the fields, their types, constraints (required, min/max, format), and any cross-field validation rules."
