#!/usr/bin/env octave

% Computes Masseyized Colley rankings on data as
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
% Deprecated.
% teams = textread(args{2}, '%*d,%s');
fid = fopen(args{2}, 'r');
teams = textscan(fid, '%*d,%s'){1};
fclose(fid);

numteams = max(max(games(:,3)), max(games(:,6)));

% In this "Masseyized Colley" we use the M of Massey
% rather than the C of Colley.
M = zeros(numteams);
b = zeros(numteams, 1);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  M(team1, team2) -= 1;
  M(team2, team1) -= 1;
  M(team1, team1) += 1;
  M(team2, team2) += 1;

  diff = score1 - score2;
  if (diff > 0)
    b(team1, 1) += 1;
    b(team2, 1) -= 1;
  elseif (diff < 0)
    b(team1, 1) -= 1;
    b(team2, 1) += 1;
  endif
  % if (diff == 0) no change to b is necessary, as we conceptually count it as
  % 1/2 win and 1/2 loss for each team
endfor

b /= 2;
b += 1;

r = M \ b;

num = 1:numteams;
num = num';

r = sortrows([num r], -2);

printf('rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor

