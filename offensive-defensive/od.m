#!/usr/bin/env octave

% Computes Offensive-Defensive  rankings on data as
% downloaded from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs defensive, offensive, and
% overall rating.
% Example invocation:

% od.m scores.php teams.php [seasonstart seasonend]

% Providing seasonstart and seasonend, in the form of
% yyyymmdd, will cause the algorithm to apply a weight
% corresponding to the fraction of the season that has
% passed. That is a game played when only 1/10 of the
% season has elapsed will have 1/10 the weight of games
% played on the last day of the season.

% For detailed informaiton on the algorithm see
% chapter seven in
% "Who's #1?: The Science of Rating and Ranking."

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

numgames = zeros(numteams);
scores = zeros(numteams);

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


  % Accumulate scores.
  scores(team1, team2) += score2 * weight;
  scores(team2, team1) += score1 * weight;

  numgames(team1, team2) += 1;
  numgames(team2, team1) += 1;
endfor

% Change the cumulative scores to averages per game.
A = scores ./ numgames;
A(isnan(A)) = 0;

% Ensure total support here.
epsilon = 0.001;
A = A + epsilon * (ones(numteams) - eye(numteams));

% Calculate the defensive ratings, how many times to converge?
d = ones(numteams, 1);
for i = 1:100
  d = A * (1 ./ (A' * (1 ./ d)));
endfor

% Then calculate the offensive and overall ratings.
o = A' * (1 ./ d);
r = o ./ d;

num = 1:numteams;
num = num';

r = sortrows([num r], -2);
o = sortrows([num o], -2);
d = sortrows([num d], 2);

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

% Book proposes building regression models in the form of:
% alpha(o1 - o2) + beta(d1 - d2) = s1 - s2
% from these offensive and defensive ratings, go nuts.

ranks = [];
diffs = [];

for i = 1:rows(games)
  team1 = games(i, 3);
  team2 = games(i, 6);

  score1 = games(i, 5);
  score2 = games(i, 8);

  rank1 = o(team1, 2) - o(team2, 2);
  rank2 = d(team1, 2) - d(team2, 2);
  diff = score1 - score2;

  ranks = [ranks; [rank1 rank2]];
  diffs = [diffs; [diff]];
endfor

B = ranks \ diffs;

printf("\nRegression, alpha(o diff) + beta(d diff) = spread\n");
printf("alpha %d\n", B(1,1));
printf("beta  %d\n", B(2,1));
