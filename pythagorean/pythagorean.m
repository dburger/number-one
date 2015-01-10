#!/usr/bin/env octave

% Computes Colley pythagorean expectations on data
% as downloaded from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% pythagorean.m scores.php teams.php

% For detailed informaiton on the algorithm see
% chapter four in
% "Who's #1?: The Science of Rating and Ranking."

% IMPORTANT!: The constant exponent below if for NFL
% data. Different sports have different accepted
% standard values.

% Output sorts the teams from lucky to unlucky with
% columns actual, expected, difference.

args = argv();

games = csvread(args{1});
teams = textread(args{2}, '%*d,%s');

exponent = 2.274;

numteams = max(max(games(:,3)), max(games(:,6)));

% Store a matrix of wins, M(i, j) tracks wins for i by
% += 1 if i beat j.
M = zeros(numteams, numteams);

% Points for and against.
f = zeros(numteams, 1);
a = zeros(numteams, 1);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  f(team1, 1) += score1;
  a(team1, 1) += score2;
  f(team2, 1) += score2;
  a(team2, 1) += score1;

  diff = score1 - score2;
  if (diff > 0)
    M(team1, team2) += 1;
  else
    M(team2, team1) += 1;
  endif
endfor

% Column 1: Actual winning percentage.
% Column 2: Expected winning percentage.
% Column 3: Difference
r = zeros(numteams, 3);

for i = 1:numteams
  wins = sum(M(i, :));
  losses = sum(M(:, i));
  r(i, 1) = wins / (wins + losses);
  r(i, 2) = 1 / (1 + (a(i, 1) / f(i, 1)) ^ exponent);
  r(i, 3) = r(i, 1) - r(i, 2);
endfor

num = 1:numteams;
num = num';

% Sort by luckiest.
r = sortrows([num r], -4);

printf('luckiest: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f %f %f\n', i, teams{r(i,1)}, r(i,2), r(i,3), r(i,4))
endfor

