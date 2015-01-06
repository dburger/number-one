#!/usr/bin/env octave

% massey.m scores.php teams.php

args = argv();

games = csvread(args{1});
tmnames = textread(args{2}, '%*d,%s');

teams = max(max(games(:,3)), max(games(:,6)));

M = zeros(teams, teams);
f = zeros(teams, 1);
a = zeros(teams, 1);
p = zeros(teams, 1);

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


T = diag(diag(M), teams, teams);
P = -1 * (M - T);

M(teams, :) = 1;
p(teams, 1) = 0;

r = M \ p;

d = (T + P) \ (T * r - f);
o = r - d;

num = 1:teams;
num = num';

r = [num r];
o = [num o];
d = [num d];

r = sortrows(r, -2);
o = sortrows(o, -2);
d = sortrows(d, -2);

printf("rankings: ====================\n")
for i = 1:rows(r)
  printf('%d %s %f\n', i, tmnames{r(i,1)}, r(i,2))
endfor

printf("offense: ====================\n")
for i = 1:rows(o)
  printf('%d %s %f\n', i, tmnames{o(i,1)}, o(i,2))
endfor

printf("defense: ====================\n")
for i = 1:rows(d)
  printf('%d %s %f\n', i, tmnames{d(i,1)}, d(i,2))
endfor
