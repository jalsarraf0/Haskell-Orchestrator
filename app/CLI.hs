-- | CLI option parsing for the Orchestrator executable.
module CLI
  ( Command (..)
  , Options (..)
  , parseOptions
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Options.Applicative

-- | Top-level CLI options.
data Options = Options
  { optConfigFile :: !(Maybe FilePath)
  , optVerbose    :: !Bool
  , optJSON       :: !Bool
  , optJobs       :: !(Maybe Int)
  , optCommand    :: !Command
  } deriving stock (Show)

-- | CLI subcommands.
data Command
  = CmdScan !FilePath
  | CmdValidate !FilePath
  | CmdDiff !FilePath
  | CmdPlan !FilePath
  | CmdDemo
  | CmdDoctor
  | CmdInit
  | CmdExplain !Text
  | CmdVerify
  | CmdRules
  deriving stock (Show)

parseOptions :: ParserInfo Options
parseOptions = info (optionsParser <**> helper)
  ( fullDesc
    <> header "orchestrator — GitHub Actions workflow standardization and governance"
    <> progDesc "Discover workflow sprawl, detect drift, validate against policies, \
                \and generate remediation plans. Run 'orchestrator demo' for a quick tour."
    <> footer "Community Edition. For multi-repo batch scanning, see Business edition. \
              \For org-wide governance, see Enterprise edition."
  )

optionsParser :: Parser Options
optionsParser = Options
  <$> optional (strOption
        ( long "config"
        <> short 'c'
        <> metavar "FILE"
        <> help "Configuration file (default: .orchestrator.yml)"
        ))
  <*> switch
        ( long "verbose"
        <> short 'v'
        <> help "Enable verbose output"
        )
  <*> switch
        ( long "json"
        <> help "Output results as JSON"
        )
  <*> optional (option auto
        ( long "jobs"
        <> short 'j'
        <> metavar "N"
        <> help "Number of parallel workers (default: conservative)"
        ))
  <*> commandParser

commandParser :: Parser Command
commandParser = subparser
  ( command "scan"
      (info (CmdScan <$> pathArg)
        (progDesc "Scan workflows and evaluate policies"))
  <> command "validate"
      (info (CmdValidate <$> pathArg)
        (progDesc "Validate workflow structure"))
  <> command "diff"
      (info (CmdDiff <$> pathArg)
        (progDesc "Show current issues"))
  <> command "plan"
      (info (CmdPlan <$> pathArg)
        (progDesc "Generate a remediation plan"))
  <> command "demo"
      (info (pure CmdDemo)
        (progDesc "Run demo with synthetic fixtures (no external access)"))
  <> command "doctor"
      (info (pure CmdDoctor)
        (progDesc "Diagnose environment, config, and connectivity"))
  <> command "init"
      (info (pure CmdInit)
        (progDesc "Create a new .orchestrator.yml config file"))
  <> command "explain"
      (info (CmdExplain . T.pack <$> strArgument (metavar "RULE_ID" <> help "Rule ID to explain"))
        (progDesc "Explain a policy rule in detail"))
  <> command "rules"
      (info (pure CmdRules)
        (progDesc "List all available policy rules"))
  <> command "verify"
      (info (pure CmdVerify)
        (progDesc "Verify the current configuration"))
  )

pathArg :: Parser FilePath
pathArg = strArgument (metavar "PATH" <> help "Repository path to scan")
