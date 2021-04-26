#!/usr/bin/env octave

% Computes point spread rankings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs overall, offensive, and
% defensive ratings FIXME.  Example invocation:

% point-spreads.m scores.php teams.php

% For detailed informaiton on the algorithm see
% chapter nine in
% "Who's #1?: The Science of Rating and Ranking."

args = argv();

games = csvread(args{1});
# Deprecated:
# teams = textread(args{2}, '%*d,%s');
fid = fopen(args{2}, 'r');
teams = textscan(fid, '%*d,%s'){1};
fclose(fid);

numteams = max(max(games(:,3)), max(games(:,6)));

K = zeros(numteams);
# Used to count the number of games between teams.
# This is to used to compute average differential.
g = zeros(numteams);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  K(team1, team2) += score1 - score2;
  K(team2, team1) += score2 - score1;
  g(team1, team2) += 1;
  g(team2, team1) += 1;
endfor

K = K ./ g;

K(isnan(K)) = 0;
e = ones(numteams, 1);
n = numteams;

r = K * e / n;

num = 1:numteams;
num = num';

# r = sortrows([num r], -2);

function output(type, rankings, teams)
  printf('%s rankings: =====================================\n', type)
  for i = 1:rows(rankings)
    printf('%d %s %f\n', i, teams{rankings(i,1)}, rankings(i,2))
  endfor
endfunction

output('Overall', sortrows([num r], -2), teams);

# Compute the home team advantage with a linear regression.
A = [];
b = [];

for i = 1:rows(games)
  home1 = games(i, 4);
  home2 = games(i, 7);
  if (home1 == 1)
    team1 = games(i, 3);
    team2 = games(i, 6);
    diff = games(i, 5) - games(i, 8);
  elseif (home2 == 1)
    team1 = games(i, 6);
    team2 = games(i, 3);
    diff = games(i, 8) - games(i, 5);
  else
    continue;
  endif
  rating1 = r(team1, 1);
  rating2 = r(team2, 1);
  A = [A; [1 rating1 rating2]];
  b = [b; [diff]];
endfor

x = A \ b;

printf("diff = %d + %d*hr + %d*ar\n", x(1, 1), x(2, 1), x(3, 1));
