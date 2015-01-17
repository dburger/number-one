#!/usr/bin/env octave

% Computes Markov rankings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% markov.m scores.php teams.php

% For detailed informaiton on the algorithm see
% chapter six in
% "Who's #1?: The Science of Rating and Ranking."

args = argv();

games = csvread(args{1});
teams = textread(args{2}, '%*d,%s');

numteams = max(max(games(:,3)), max(games(:,6)));

S = zeros(numteams, numteams);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  % Using points allowed.
  S(team1, team2) = score2;
  S(team2, team1) = score1;
endfor

for i = 1:rows(S)
  S(i, :) *= 1 / sum(S(i, :));
endfor

% Need to compute "stationary vector"  or "dominant eigenvector" of
% S.
S
