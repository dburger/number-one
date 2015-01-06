#!/usr/bin/env octave

% Computes Massey ratings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs overall, offensive, and
% defensive ratings.  Example invocation:

% massey.m scores.php teams.php

% For detailed informaiton on the algorithm see
% chapter two in
% "Who's #1?: The Science of Rating and Ranking."

args = argv();

games = csvread(args{1});
teams = textread(args{2}, '%*d,%s');

numteams = max(max(games(:,3)), max(games(:,6)));

M = zeros(numteams, numteams);
f = zeros(numteams, 1);
a = zeros(numteams, 1);
p = zeros(numteams, 1);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  M(team1, team2) -= 1;
  M(team2, team1) -= 1;
  M(team1, team1) += 1;
  M(team2, team2) += 1;

  f(team1, 1) += score1;
  a(team1, 1) += score2;
  f(team2, 1) += score2;
  a(team2, 1) += score1;

  diff = score1 - score2;
  p(team1, 1) += diff;
  p(team2, 1) -= diff;
endfor


T = diag(diag(M), numteams, numteams);
P = -1 * (M - T);

% This correction forces the sum of rankings to be 0.
M(numteams, :) = 1;
p(numteams, 1) = 0;

r = M \ p;

d = (T + P) \ (T * r - f);
o = r - d;

num = 1:numteams;
num = num';

r = [num r];
o = [num o];
d = [num d];

r = sortrows(r, -2);
o = sortrows(o, -2);
d = sortrows(d, -2);

function output(type, rankings, teams)
  printf(['%s rankings: =====================================\n'], type)
  for i = 1:rows(rankings)
    printf('%d %s %f\n', i, teams{rankings(i,1)}, rankings(i,2))
  endfor
  printf('\n')
endfunction

output('Overall', r, teams);
output('Offense', o, teams);
output('Defense', d, teams);
