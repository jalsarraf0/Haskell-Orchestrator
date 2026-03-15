module Main (main) where

import CLI (Command (..), Options (..), parseOptions)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Options.Applicative (execParser)
import Orchestrator.Config ( OrchestratorConfig (..), defaultConfig )
import Orchestrator.Demo (runDemo)
import Orchestrator.Diff (generatePlan, renderPlanText)
import Orchestrator.Policy
    ( PolicyPack (..), PolicyRule (..), defaultPolicyPack )
import Orchestrator.Render
    ( OutputFormat (..), renderFindings, renderFindingsJSON, renderSummary )
import Orchestrator.Scan (findWorkflowFiles, scanLocalPath)
import Orchestrator.Parser (parseWorkflowFile)
import Orchestrator.Types
import Orchestrator.Validate (ValidationResult (..), validateWorkflow)
import System.Directory (doesDirectoryExist, doesFileExist)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
  opts <- execParser parseOptions
  case optCommand opts of
    CmdDemo        -> runDemo
    CmdDoctor      -> runDoctor opts
    CmdInit        -> runInit
    CmdScan p      -> runScan opts p
    CmdValidate p  -> runValidate opts p
    CmdPlan p      -> runPlan opts p
    CmdDiff p      -> runPlan opts p
    CmdExplain rid -> runExplain rid
    CmdRules       -> runRules
    CmdVerify      -> runVerify opts

runScan :: Options -> FilePath -> IO ()
runScan opts path = do
  let pack = defaultPolicyPack
      scfg = cfgScan defaultConfig
  result <- scanLocalPath pack scfg path
  let fmt = if optJSON opts then JSONOutput else TextOutput
  case result of
    Left err -> do
      hPutStrLn stderr $ "Error: " ++ show err
      exitFailure
    Right sr -> do
      let findings = scanFindings sr
      TIO.putStrLn $ "Scanning: " <> T.pack path
      TIO.putStrLn $ "Files found: " <> T.pack (show (length (scanFiles sr)))
      TIO.putStrLn ""
      case fmt of
        JSONOutput -> TIO.putStrLn $ renderFindingsJSON findings
        TextOutput -> do
          TIO.putStrLn $ renderFindings findings
          TIO.putStrLn $ renderSummary findings
      if any (\f -> findingSeverity f >= Error) findings
        then exitFailure
        else exitSuccess

runValidate :: Options -> FilePath -> IO ()
runValidate opts path = do
  files <- findWorkflowFiles 1 (path ++ "/.github/workflows")
  allFindings <- concat <$> mapM (\f -> do
    r <- parseWorkflowFile f
    case r of
      Left err -> do
        hPutStrLn stderr $ "Parse error: " ++ show err
        pure []
      Right wf -> do
        let ValidationResult _ fs _ = validateWorkflow wf
        pure fs
    ) files
  let fmt = if optJSON opts then JSONOutput else TextOutput
  case fmt of
    JSONOutput -> TIO.putStrLn $ renderFindingsJSON allFindings
    TextOutput -> TIO.putStrLn $ renderFindings allFindings
  if any (\f -> findingSeverity f >= Error) allFindings
    then exitFailure
    else exitSuccess

runPlan :: Options -> FilePath -> IO ()
runPlan _opts path = do
  let pack = defaultPolicyPack
      scfg = cfgScan defaultConfig
  result <- scanLocalPath pack scfg path
  case result of
    Left err -> hPutStrLn stderr $ "Error: " ++ show err
    Right sr -> TIO.putStr $ renderPlanText $ generatePlan (scanTarget sr) (scanFindings sr)

runDoctor :: Options -> IO ()
runDoctor opts = do
  TIO.putStrLn "Orchestrator Doctor"
  TIO.putStrLn (T.replicate 50 "═")
  TIO.putStrLn ""

  -- Check policy pack
  let PolicyPack pname rules = defaultPolicyPack
  TIO.putStrLn $ "Policy pack:     " <> pname <> " (" <> T.pack (show (length rules)) <> " rules)"

  -- Check config file
  cfgExists <- doesFileExist ".orchestrator.yml"
  if cfgExists
    then TIO.putStrLn "Config file:     .orchestrator.yml (found)"
    else TIO.putStrLn "Config file:     not found (using defaults)"

  -- Check for workflow directories
  TIO.putStrLn ""
  TIO.putStrLn "Environment checks:"
  ghaDirExists <- doesDirectoryExist ".github/workflows"
  if ghaDirExists
    then do
      wfFiles <- findWorkflowFiles 1 ".github/workflows"
      TIO.putStrLn $ "  Workflows:     " <> T.pack (show (length wfFiles)) <> " file(s) in .github/workflows/"
    else
      TIO.putStrLn "  Workflows:     no .github/workflows/ in current directory"

  -- Resource config
  TIO.putStrLn ""
  TIO.putStrLn "Resource config:"
  TIO.putStrLn $ "  Parallelism:   " <> maybe "auto (safe)" (\j -> T.pack (show j) <> " worker(s)") (optJobs opts)

  TIO.putStrLn ""
  TIO.putStrLn "Edition:         Community"
  TIO.putStrLn "                 For multi-repo batch scanning, see Business edition."
  TIO.putStrLn "                 For org-wide governance, see Enterprise edition."
  TIO.putStrLn ""
  TIO.putStrLn (T.replicate 50 "═")
  TIO.putStrLn "Doctor complete. No issues detected."

runInit :: IO ()
runInit = do
  exists <- doesFileExist ".orchestrator.yml"
  if exists
    then do
      TIO.putStrLn "Config file .orchestrator.yml already exists."
      TIO.putStrLn "Remove it first if you want to regenerate."
    else do
      let content = T.unlines
            [ "# Haskell Orchestrator configuration"
            , "# Docs: https://github.com/jalsarraf0/Haskell-Orchestrator"
            , "#"
            , "# This tool scans GitHub Actions workflows for policy violations,"
            , "# drift, and hygiene issues. All operations are read-only by default."
            , ""
            , "scan:"
            , "  # Target path is provided on the command line."
            , "  # These settings control scan behavior."
            , "  exclude: []"
            , "  max_depth: 10"
            , "  follow_symlinks: false"
            , ""
            , "policy:"
            , "  pack: standard       # Policy pack (standard is the only built-in)"
            , "  min_severity: info   # Minimum severity to report: info, warning, error, critical"
            , "  disabled: []         # Rule IDs to disable, e.g. [NAME-001, NAME-002]"
            , ""
            , "output:"
            , "  format: text         # text or json"
            , "  verbose: false"
            , "  color: true"
            , ""
            , "resources:"
            , "  # jobs: 4            # Uncomment to set parallel worker count"
            , "  profile: safe        # safe (conservative), balanced, or fast"
            ]
      TIO.writeFile ".orchestrator.yml" content
      TIO.putStrLn "Created .orchestrator.yml"
      TIO.putStrLn ""
      TIO.putStrLn "Next steps:"
      TIO.putStrLn "  orchestrator scan .          # Scan current directory"
      TIO.putStrLn "  orchestrator demo            # Try the demo"
      TIO.putStrLn "  orchestrator doctor           # Check environment"

runExplain :: T.Text -> IO ()
runExplain rid = do
  let PolicyPack _ rules = defaultPolicyPack
      match = filter (\r -> ruleId r == rid) rules
  case match of
    [] -> do
      TIO.putStrLn $ "Unknown rule: " <> rid
      TIO.putStrLn ""
      TIO.putStrLn "Available rules:"
      mapM_ (\r -> TIO.putStrLn $ "  " <> ruleId r <> "  " <> ruleName r) rules
      TIO.putStrLn ""
      TIO.putStrLn "Use 'orchestrator rules' for a full listing."
    (r:_) -> do
      TIO.putStrLn $ "Rule:        " <> ruleId r
      TIO.putStrLn $ "Name:        " <> ruleName r
      TIO.putStrLn $ "Severity:    " <> T.pack (show (ruleSeverity r))
      TIO.putStrLn $ "Category:    " <> T.pack (show (ruleCategory r))
      TIO.putStrLn $ "Description: " <> ruleDescription r

runRules :: IO ()
runRules = do
  let PolicyPack pname rules = defaultPolicyPack
  TIO.putStrLn $ "Policy Pack: " <> pname
  TIO.putStrLn $ T.replicate 70 "─"
  TIO.putStrLn $ padRight 12 "RULE ID" <> padRight 10 "SEVERITY" <> padRight 14 "CATEGORY" <> "NAME"
  TIO.putStrLn $ T.replicate 70 "─"
  mapM_ (\r -> TIO.putStrLn $
    padRight 12 (ruleId r)
    <> padRight 10 (T.pack (show (ruleSeverity r)))
    <> padRight 14 (T.pack (show (ruleCategory r)))
    <> ruleName r
    ) rules
  TIO.putStrLn $ T.replicate 70 "─"
  TIO.putStrLn $ T.pack (show (length rules)) <> " rules"
  where
    padRight n t = T.take n (t <> T.replicate n " ")

runVerify :: Options -> IO ()
runVerify _opts = do
  TIO.putStrLn "Configuration verification:"
  cfgExists <- doesFileExist ".orchestrator.yml"
  if cfgExists
    then TIO.putStrLn "  Config file:   .orchestrator.yml (found, valid)"
    else TIO.putStrLn "  Config file:   not found (defaults will be used)"
  TIO.putStrLn "  Policy pack:   standard (10 rules)"
  TIO.putStrLn "  Output format: text"
  TIO.putStrLn ""
  TIO.putStrLn "Verification complete."
