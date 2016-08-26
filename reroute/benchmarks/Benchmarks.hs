{-# LANGUAGE OverloadedStrings, DataKinds #-}

module Main where

import Web.Routing.Combinators
import Web.Routing.SafeRouting

import Criterion.Main
import qualified Data.Text as T
import Data.List (permutations, foldl')
import System.Random (mkStdGen, randomRs)
import Data.Maybe (listToMaybe, fromMaybe)

buildPath :: [T.Text] -> PathInternal '[]
buildPath = toInternalPath . static . T.unpack . T.intercalate "/"

buildPathMap :: [([T.Text], a)] -> PathMap a
buildPathMap =
  foldl' (\t (route, val) -> insertPathMap' (buildPath route) (const val) t) mempty

lookupPathMapM :: [[T.Text]] -> PathMap Int -> Int
lookupPathMapM rs m =
  foldl' (\z route -> fromMaybe z (listToMaybe $ match m route)) 0 rs

benchmarks :: [Benchmark]
benchmarks =
  [ env setupSafeMap $ \ ~(safeMap, routes') ->
    bgroup "SafeRouting"
    [ bench "static-lookup" $ whnf (lookupPathMapM routes') safeMap
    ]
  ]
  where
    strlen = 10
    seglen = 5
    num = 10
    routes = rndRoutes strlen seglen num
    routesList = zip routes [1..]
    setupSafeMap = return (buildPathMap routesList, routes)

main :: IO ()
main = defaultMain benchmarks

chunks :: Int -> [a] -> [[a]]
chunks n xs =
  let (ys, xs') = splitAt n xs
  in ys : chunks n xs'

-- | Generate a number of paths consisting of a fixed number of fixed length
-- strings ("path segments") where the content of the segments are letters in
-- random order. Contains all permutations with the path.
rndRoutes ::
     Int -- ^ Length of each string
  -> Int -- ^ Number of segments
  -> Int -- ^ Number of routes
  -> [[T.Text]]
rndRoutes strlen seglen num =
  take num $ concatMap permutations $ chunks seglen $ map T.pack $
    chunks strlen $ randomRs ('a', 'z') $ mkStdGen 1234
