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

  % Using wins, the loser "votes for" the winner.
  if (score1 > score2)
    S(team2, team1) += 1;
  elseif (score2 > score1)
    S(team1, team2) += 1;
  else
    S(team2, team1) += 0.5;
    S(team1, team2) += 0.5;
  endif
endfor

% Normalize the rows.
for i = 1:rows(S)
  t = sum(S(i, :));
  if (t > 0)
    S(i, :) *= 1 / t;
  endif
endfor

% To force stochasticity can introduce "teleportation matrix.
% Here beta = .5 as suggested for NCAA basketball.
S = 0.5 * S + (1 - 0.5) / numteams * ones(numteams, numteams);

% Need to compute "stationary vector"  or "dominant eigenvector" of
% S. This is stolen from
% http://stackoverflow.com/questions/16888303/dtmc-markov-chain-how-to-get-the-stationary-vector
r = [S' - eye(numteams, numteams); ones(1, numteams)] \ [zeros(numteams, 1); 1];

num = 1:numteams;
num = num';

r = sortrows([num r], -2);

printf('rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor
