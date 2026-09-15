///|
test "doctor formatter is available to the CLI package" {
  let report = @moonsh.audit_workspace([
    "moon.mod", "moon.pkg", "README.md", "LICENSE", ".github/workflows/ci.yml", "main.mbt",
    "main_wbtest.mbt",
  ])
  assert_eq(report.score, 100)
  assert_eq(report.untested_packages, 0)
  assert_true(
    @moonsh.format_workspace_audit_json(report).contains("\"grade\":\"A\""),
  )
}
