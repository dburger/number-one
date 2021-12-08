#!/usr/bin/env octave

% Computes Markov rankings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% markov.m scores.php teams.php [seasonstart seasonend]

% Providing seasonstart and seasonend, in the form of
% yyyymmdd, will cause the algorithm to apply a weight
% corresponding to the fraction of the season that has
% passed. That is a game played when only 1/10 of the
% season has elapsed will have 1/10 the weight of games
% played on the last day of the season.

% For detailed informaiton on the algorithm see
% chapter six in
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

% Wins tracked in matrix 1.
S = zeros(numteams, numteams);
% Points given up tracked in matrix 2.
S(:, :, 2) = zeros(numteams, numteams);

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

  % In matrix 1, using wins, the loser "votes for" the winner.
  if (score1 > score2)
    S(team2, team1, 1) += 1 * weight;
  elseif (score2 > score1)
    S(team1, team2, 1) += 1 * weight;
  else
    S(team2, team1, 1) += 0.5 * weight;
    S(team1, team2, 1) += 0.5 * weight;
  endif

  % In matrix 2, using scores, a team votes for the other team
  % with how many points it gave up to that team.
  S(team2, team1, 2) += score1 * weight;
  S(team1, team2, 2) += score2 * weight;
endfor

% Normalize the rows.
for i = 1:2
  for j = 1:rows(S(:, :, i))
    t = sum(S(j, :, i));
    if (t > 0)
      S(j, :, i) *= 1 / t;
    else
      % No losses, could evenly vote for any team including itself
      % S(j, :, i) = 1 / numteams;
      % or here, we vote only for thyself.
      S(j, j, i) = 1;
    endif
  endfor
endfor

% Aggregate the different stats matrices down into a single
% aggregated matrix.
A = zeros(numteams, numteams);
for i = 1:2
  % Perhaps the combination weighting should not be 0.5 here.
  % For example, perhaps wins is more important than points.
  A = A + 0.5 * S(:, :, i);
endfor

% To force stochasticity can introduce "teleportation matrix."
% Here beta = .5 as suggested for NCAA basketball.
% This should not be necessary unless you have stats that result
% in a row of zeros. For example, wins are votes for other teams
% and you have an undefeated team.
% beta = 0.5
% A = beta * A + (1.0 - beta) / numteams * ones(numteams, numteams);

% Need to compute "stationary vector"  or "dominant eigenvector" of
% S. This is stolen from
% http://stackoverflow.com/questions/16888303/dtmc-markov-chain-how-to-get-the-stationary-vector

r = [A' - eye(numteams); ones(1, numteams)] \ [zeros(numteams, 1); 1];

num = 1:numteams;
num = num';

r = sortrows([num r], -2);

printf('rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor
