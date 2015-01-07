#!/usr/bin/env octave

% Computes "Colleyized Massey" rankings on data as
% downloaded from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% massey-colley.m scores.php teams.php

% For detailed informaiton on the algorithm see
% chapter three in
% "Who's #1?: The Science of Rating and Ranking."

args = argv();

games = csvread(args{1});
teams = textread(args{2}, '%*d,%s');

numteams = max(max(games(:,3)), max(games(:,6)));

C = 2 * eye(numteams);
p = zeros(numteams, 1);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  C(team1, team2) -= 1;
  C(team2, team1) -= 1;
  C(team1, team1) += 1;
  C(team2, team2) += 1;

  % In this "Colleyized Massey" the right hand side is
  % the point differential instead of win loss differential.
  diff = score1 - score2;
  p(team1, 1) += diff;
  p(team2, 1) -= diff;
endfor

r = C \ p;

num = 1:numteams;
num = num';

r = sortrows([num r], -2);

printf('rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor
printf('\n')
