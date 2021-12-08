#!/usr/bin/octave -qf

% Computes Colley rankings on data as downloaded
% from http://www.masseyratings.com/data.php
% in the "Matlab Games" and "Matlab Teams" formats.
% Team one identifier and score found in columns
% 3 and 5, team two identifier and score found in
% columns 6 and 8. Outputs a single overall rating.
% Example invocation:

% colley.m scores.php teams.php [seasonstart seasonend]

% Providing seasonstart and seasonend, in the form of
% yyyymmdd, will cause the algorithm to apply a weight
% corresponding to the fraction of the season that has
% passed. That is a game played when only 1/10 of the
% season has elapsed will have 1/10 the weight of games
% played on the last day of the season.

% For detailed informaiton on the algorithm see
% chapter three in
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

C = 2 * eye(numteams);
b = zeros(numteams, 1);

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

  C(team1, team2) -= 1 * weight;
  C(team2, team1) -= 1 * weight;
  C(team1, team1) += 1 * weight;
  C(team2, team2) += 1 * weight;

  diff = score1 - score2;

  if (diff > 0)
    b(team1, 1) += 1 * weight;
    b(team2, 1) -= 1 * weight;
  elseif (diff < 0)
    b(team1, 1) -= 1 * weight;
    b(team2, 1) += 1 * weight;
  endif
  % if (diff == 0) no change to b is necessary, as we conceptually count it as
  % 1/2 win and 1/2 loss for each team
endfor

b /= 2;
b += 1;

r = C \ b;

num = 1:numteams;
num = num';

r = sortrows([num r], -2);

printf('rankings: =====================================\n')
for i = 1:rows(r)
  printf('%d %s %f\n', i, teams{r(i,1)}, r(i,2))
endfor
