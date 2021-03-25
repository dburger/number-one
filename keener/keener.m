#!/usr/bin/env octave

% Computes Keener rankings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% keener.m scores.php teams.php

% For detailed informaiton on the algorithm see
% chapter four in
% "Who's #1?: The Science of Rating and Ranking."

% Note that some simplifying assumptions have been made
% under the assumption you have irreducibility and primitivity
% in your data without further adjustment. This works,
% for example, with full season of NFL data.

args = argv();

games = csvread(args{1});
teams = textread(args{2}, '%*d,%s');

numteams = max(max(games(:,3)), max(games(:,6)));

% Will hold the stat we are tracking.
A = zeros(numteams);
% Will hold the game counts between teams.
G = zeros(numteams);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  A(team1, team2) += score1;
  A(team2, team1) += score2;
  G(team1, team2) += 1;
  G(team2, team1) += 1;
endfor

% T used as temporary matrix to calculate the adjustments.
T = zeros(numteams);

% Laplace's rule of succession adjustment.
for i = 1:rows(A)
  for j = 1:columns(A)
    T(i, j) = (A(i, j) + 1) / (A(i, j) + A(j, i) + 2);
  endfor
endfor

A = T;
T = zeros(numteams);

% Skewing adjustment.
for i = 1:rows(A)
  for j = 1:columns(A)
    T(i, j) = 0.5 + (sign(A(i, j) - 0.5) * sqrt(abs(2 * A(i, j) - 1))) / 2;
  endfor
endfor

A = T;

% This seems to make things worse for NBA. Note that the book talks
% about this not being helpful when you have already done a skewing
% adjustment and the number of games is already similar.
% Number of games adjustment.
% A = A ./ G;
% A(isnan(A)|isinf(A)) = 0;

% Perturbation, could be helpful to force irreducibility and primitivty.
% A = A + (0.0001 * (ones(numteams, 1) * ones(1, numteams)))

% Power method, note that if you needed to force irreducibility
% or primitivity you need to adjust this approach. This shouldn't
% be necessary for data from the full 16 game NFL season.

x = 1 / numteams * ones(numteams, 1);

% Same as this:
% for i = 1:1000
%   t = A * x;
%   x = A / sum(t);
% endfor

for i = 1:1000
  y = A * x;
  v = sum(y);
  x = y / v;
endfor

% With enough iterations x converges to the ratings vector.
r = x;

num = 1:numteams;
num = num';

r = sortrows([num r], -2);

printf('rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor
