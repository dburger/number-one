#!/usr/bin/octave -qf

% Simple Rating System described at
% http://www.pro-football-reference.com/blog/?p=37
% Example invocation:

% simple.m scores.php teams.php

args = argv();

games = csvread(args{1});
teams = textread(args{2}, '%*d,%s');

numteams = max(max(games(:,3)), max(games(:,6)));

C = zeros(numteams);
b = zeros(numteams, 1);

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  C(team1, team2) += 1;
  C(team2, team1) += 1;

  score1 = games(i, 5);
  score2 = games(i, 8);

  b(team1, 1) += (score1 - score2);
  b(team2, 1) += (score2 - score1);
endfor

for i = 1:rows(C)
  t = sum(C(i, :));
  b(i, 1) /= -t;
  C(i, :) /= t;
  C(i, i) = -1;
endfor

r = C \ b;

num = 1:numteams;
num = num';

r = sortrows([num r], -2);

printf('rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor
