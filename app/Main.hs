{-# LANGUAGE OverloadedStrings #-}

module Main where


import Control.Monad (forM_)
import Control.Search
import Data.Coolean ((!&&))
import Data.Function ((&))
import Data.List (isPrefixOf)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Language.FGG.DeBruijn as DB
import qualified Language.FGG.Named as N
import System.Exit (ExitCode)
import System.IO (hClose)
import System.IO.Temp (withTempFile)
import System.Process (readProcessWithExitCode)
import Test.Feat (values)


-- * Main function

fgg :: FilePath -> IO (ExitCode, String, String)
fgg fp = do
  (exitCode, stdout, stderr) <-
    readProcessWithExitCode "go" ["run", "github.com/rhu1/fgg", "-fgg", "-eval=-1", fp] ""
  let stdout' = stdout
              & lines
              & filter (not . ("[Warning]" `isPrefixOf`))
              & unlines
  return (exitCode, stdout', stderr)

allProgs :: [DB.Prog ()]
allProgs = concatMap snd (take 15 values)

wellTypedProgs :: IO [DB.Prog ()]
wellTypedProgs = search 15 (DB.checkProg' opts)
  where
    opts = DB.TCSOpts
      { DB.optMethMin     = Just 1
      , DB.optFldMin      = Just 1
      , DB.optEmptyStrMax = Just 2
      , DB.optEmptyIntMax = Just 1
      }

main :: IO ()
main = do
  -- progs <- return allProgs
  progs <- wellTypedProgs
  forM_ progs $ \prog -> do
    let progSrc = N.prettyProg (DB.convProg prog)
    T.putStrLn progSrc
    T.putStrLn ""
