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
f = zeros(numteams, 1);
a = zeros(numteams, 1);
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
  f(team1, 1) += score1;
  a(team1, 1) += score2;
  f(team2, 1) += score2;
  a(team2, 1) += score1;

  diff = score1 - score2;
  p(team1, 1) += diff;
  p(team2, 1) -= diff;
endfor

r = C \ p;

% Here we add some offense and defense rating computations. See the tail end
% of chapter two in
% "Who's #1?: The Science of Rating and Ranking." where it talks about how
% to add such ratings to Massey, here we do the same thing for
% Colleyized Massey.

T = diag(diag(C), numteams, numteams);
P = -1 * (C - T);

d = (T + P) \ (T * r - f)
o = r - d;

num = 1:numteams;
num = num';

r = sortrows([num r], -2);
o = sortrows([num o], -2);
d = sortrows([num d], -2);

function output(type, rankings, teams)
  printf('%s rankings: =====================================\n', type)
  for i = 1:rows(rankings)
    printf('%d %s %f\n', i, teams{rankings(i,1)}, rankings(i,2))
  endfor
endfunction

output('Overall', r, teams);
printf('\n')
output('Offense', o, teams);
printf('\n')
output('Defense', d, teams);
