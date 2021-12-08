#!/usr/bin/env octave

% Computes Keener rankings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% keener.m scores.php teams.php [seasonstart seasonend]

% Providing seasonstart and seasonend, in the form of
% yyyymmdd, will cause the algorithm to apply a weight
% corresponding to the fraction of the season that has
% passed. That is a game played when only 1/10 of the
% season has elapsed will have 1/10 the weight of games
% played on the last day of the season.

% For detailed informaiton on the algorithm see
% chapter four in
% "Who's #1?: The Science of Rating and Ranking."

% Note that some simplifying assumptions have been made
% under the assumption you have irreducibility and primitivity
% in your data without further adjustment. This works,
% for example, with full season of NFL data.

datetmpl = '%Y%m%d';

args = argv();

games = csvread(args{1});
% Deprecated.
% teams = textread(args{2}, '%*d,%s');
fid = fopen(args{2}, 'r');
teams = textscan(fid, '%*d,%s'){1};
fclose(fid);

if (length(args) == 4)
  [seasonstart, nchars] = strptime(args{3}, datetmpl);
  if (nchars == 0)
    error('seasonstart does not parse.');
  endif
  seasonstart = mktime(seasonstart);
  [seasonend, nchars] = strptime(args{4}, datetmpl);
  if (nchars == 0)
    error('seasonend does not parse.');
  endif
  seasonend = mktime(seasonend);
  seasonlen = seasonend - seasonstart;
  if (seasonlen <= 0)
    error('Invalid seasonlen.')
  end
endif

numteams = max(max(games(:,3)), max(games(:,6)));

% Will hold the stat we are tracking.
A = zeros(numteams);
% Will hold the game counts between teams.
G = zeros(numteams);

for i = 1:rows(games)
  gamestart = mktime(strptime(num2str(games(i, 2)), datetmpl));

  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  weight = 1;

  if (exist('seasonstart', 'var') == 1)
    offset = gamestart - seasonstart;
    if (offset < 0)
      error('Game offset less than 0');
    endif
    weight = (gamestart - seasonstart) / seasonlen;
  endif


  A(team1, team2) += score1 * weight;
  A(team2, team1) += score2 * weight;
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

printf('Overall rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor
