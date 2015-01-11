#!/usr/bin/env octave

% Computes Elo rankings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% elo.m scores.php teams.php

% For detailed informaiton on the algorithm see
% chapter five in
% "Who's #1?: The Science of Rating and Ranking."

% Returns the new elo rating for team1 with score1 and elo1
% against team2 with score2 and elo2.
function retval = newelo(score1, score2, elo1, elo2)
  diff = score1 - score2;
  if (diff > 0)
    S = 1;
  elseif (diff < 0)
    S = 0;
  else
    S = 0.5;
  endif
  u = 1 / (1 + 10 ^ (-1 * (elo1 - elo2) / 400));
  % Note the K = 20 here.
  retval = elo1 + 20 * (S - u);
endfunction

args = argv();

games = csvread(args{1});
teams = textread(args{2}, '%*d,%s');

numteams = max(max(games(:,3)), max(games(:,6)));

% Start every team with a rating of 1500.
elos = 1500 * ones(numteams, 1);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  elo1 = elos(team1, 1);
  elo2 = elos(team2, 1);

  score1 = games(i, 5);
  score2 = games(i, 8);

  elos(team1, 1) = newelo(score1, score2, elo1, elo2);
  elos(team2, 1) = newelo(score2, score1, elo2, elo1);
endfor

num = 1:numteams;
num = num';

elos = sortrows([num elos], -2);

printf('rankings: =====================================\n')
for i = 1:rows(elos)
  printf('%d %s %f\n', i, teams{elos(i,1)}, elos(i,2))
endfor
