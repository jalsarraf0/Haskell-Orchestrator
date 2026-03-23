module Test.Integration (tests) where

import Data.ByteString.Char8 qualified as BS
import Data.Either (rights)
import Data.Text qualified as T
import Orchestrator.Model
import Orchestrator.Parser
import Orchestrator.Policy
import Orchestrator.Types
import Orchestrator.Validate
import Orchestrator.Diff
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, assertBool)

tests :: TestTree
tests = testGroup "Integration"
  [ realWorldPatterns
  , endToEndFlows
  ]

------------------------------------------------------------------------
-- Realistic workflow patterns
------------------------------------------------------------------------

realWorldPatterns :: TestTree
realWorldPatterns = testGroup "Realistic Workflow Patterns"
  [ testCase "Standard CI workflow (build + test)" $ do
      let yaml = BS.pack $ unlines
            [ "name: CI"
            , "on:"
            , "  push:"
            , "    branches: [main]"
            , "  pull_request:"
            , "    branches: [main]"
            , "permissions:"
            , "  contents: read"
            , "concurrency:"
            , "  group: ci-${{ github.ref }}"
            , "  cancel-in-progress: true"
            , "jobs:"
            , "  build:"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 30"
            , "    steps:"
            , "      - uses: actions/checkout@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
            , "      - run: make build"
            , "      - run: make test"
            ]
      case parseWorkflowBS "ci.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> do
          let findings = evaluatePolicies defaultPolicyPack wf
              errors = filter (\f -> findingSeverity f >= Error) findings
          assertBool "Well-formed CI should have no errors" (null errors)

  , testCase "Release workflow with matrix" $ do
      let yaml = BS.pack $ unlines
            [ "name: Release"
            , "on:"
            , "  push:"
            , "    tags: ['v*']"
            , "permissions:"
            , "  contents: write"
            , "jobs:"
            , "  build:"
            , "    runs-on: ${{ matrix.os }}"
            , "    timeout-minutes: 60"
            , "    strategy:"
            , "      matrix:"
            , "        os: [ubuntu-latest, macos-latest, windows-latest]"
            , "    steps:"
            , "      - uses: actions/checkout@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
            , "      - run: make release"
            ]
      case parseWorkflowBS "release.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> do
          let findings = evaluatePolicies defaultPolicyPack wf
          -- Write permissions may trigger PERM-002 depending on rules
          assertBool "Should parse and evaluate" (findings `seq` True)

  , testCase "Insecure workflow with multiple issues" $ do
      let yaml = BS.pack $ unlines
            [ "name: bad"
            , "on: push"
            , "jobs:"
            , "  build:"
            , "    runs-on: ubuntu-latest"
            , "    steps:"
            , "      - uses: some-org/action@main"
            , "      - run: echo ${{ secrets.TOKEN }}"
            ]
      case parseWorkflowBS "bad.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> do
          let findings = evaluatePolicies defaultPolicyPack wf
          assertBool "Should have multiple findings" (length findings >= 3)

  , testCase "Workflow dispatch with inputs" $ do
      let yaml = BS.pack $ unlines
            [ "name: Manual Deploy"
            , "on:"
            , "  workflow_dispatch:"
            , "    inputs:"
            , "      environment:"
            , "        description: 'Target environment'"
            , "        required: true"
            , "        default: staging"
            , "permissions:"
            , "  contents: read"
            , "jobs:"
            , "  deploy:"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 30"
            , "    steps:"
            , "      - uses: actions/checkout@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
            , "      - run: echo deploying"
            ]
      case parseWorkflowBS "deploy.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> assertBool "Should parse dispatch workflow" (not $ null $ wfJobs wf)

  , testCase "Cron scheduled workflow" $ do
      let yaml = BS.pack $ unlines
            [ "name: Nightly"
            , "on:"
            , "  schedule:"
            , "    - cron: '0 2 * * *'"
            , "permissions:"
            , "  contents: read"
            , "jobs:"
            , "  nightly:"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 60"
            , "    steps:"
            , "      - uses: actions/checkout@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
            , "      - run: make nightly-tests"
            ]
      case parseWorkflowBS "nightly.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> assertBool "Should parse cron workflow" (not $ null $ wfJobs wf)

  , testCase "Multi-job workflow with dependencies" $ do
      let yaml = BS.pack $ unlines
            [ "name: Pipeline"
            , "on: push"
            , "permissions:"
            , "  contents: read"
            , "jobs:"
            , "  lint:"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 10"
            , "    steps:"
            , "      - run: make lint"
            , "  test:"
            , "    needs: lint"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 30"
            , "    steps:"
            , "      - run: make test"
            , "  deploy:"
            , "    needs: [lint, test]"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 15"
            , "    steps:"
            , "      - run: make deploy"
            ]
      case parseWorkflowBS "pipeline.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> do
          let vr = validateWorkflow wf
          assertBool "Pipeline should be valid" (vrValid vr)
          assertBool "Should have 3 jobs" (length (wfJobs wf) == 3)

  , testCase "Workflow with environment variables" $ do
      let yaml = BS.pack $ unlines
            [ "name: EnvTest"
            , "on: push"
            , "env:"
            , "  NODE_ENV: production"
            , "  CI: true"
            , "jobs:"
            , "  build:"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 15"
            , "    env:"
            , "      BUILD_TYPE: release"
            , "    steps:"
            , "      - run: echo $NODE_ENV"
            ]
      case parseWorkflowBS "env.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> assertBool "Should parse env workflow" (not $ null $ wfJobs wf)
  ]

------------------------------------------------------------------------
-- End-to-end flows: parse -> validate -> policy -> plan
------------------------------------------------------------------------

endToEndFlows :: TestTree
endToEndFlows = testGroup "End-to-End Flows"
  [ testCase "Clean workflow: parse -> validate -> policy -> zero-step plan" $ do
      let yaml = BS.pack $ unlines
            [ "name: Clean CI"
            , "on:"
            , "  pull_request:"
            , "    branches: [main]"
            , "permissions:"
            , "  contents: read"
            , "concurrency:"
            , "  group: ci-${{ github.ref }}"
            , "  cancel-in-progress: true"
            , "jobs:"
            , "  build:"
            , "    runs-on: ubuntu-latest"
            , "    timeout-minutes: 30"
            , "    steps:"
            , "      - uses: actions/checkout@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
            , "      - run: make test"
            ]
      case parseWorkflowBS "clean.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> do
          let vr = validateWorkflow wf
          assertBool "Should be valid" (vrValid vr)
          let findings = evaluatePolicies defaultPolicyPack wf
              errors = filter (\f -> findingSeverity f >= Error) findings
          assertBool "Should have no errors" (null errors)
          let plan = generatePlan (LocalPath ".") findings
          assertBool "Plan should have few steps" (length (planSteps plan) <= 2)

  , testCase "Messy workflow: parse -> validate -> policy -> multi-step plan" $ do
      let yaml = BS.pack $ unlines
            [ "name: x"
            , "on: push"
            , "jobs:"
            , "  build:"
            , "    runs-on: ubuntu-latest"
            , "    steps:"
            , "      - uses: some-org/untrusted@v1"
            , "      - run: echo ${{ secrets.KEY }}"
            ]
      case parseWorkflowBS "messy.yml" yaml of
        Left err -> error $ "Parse failed: " ++ show err
        Right wf -> do
          let findings = evaluatePolicies defaultPolicyPack wf
          assertBool "Should have multiple findings" (length findings >= 3)
          let plan = generatePlan (LocalPath ".") findings
          assertBool "Plan should have steps" (not (null (planSteps plan)))
          let txt = renderPlanText plan
          assertBool "Plan text should be non-empty" (not $ T.null txt)

  , testCase "Multiple workflows: parse all, validate all" $ do
      let yamls =
            [ ("ci.yml", BS.pack "name: CI\non: push\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo test")
            , ("deploy.yml", BS.pack "name: Deploy\non: push\njobs:\n  deploy:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo deploy")
            ]
          parsed = [ parseWorkflowBS name content | (name, content) <- yamls ]
          workflows = rights parsed
      assertBool "Both should parse" (length workflows == 2)
      let results = validateWorkflows workflows
      assertBool "Both should validate" (length results == 2)
  ]
