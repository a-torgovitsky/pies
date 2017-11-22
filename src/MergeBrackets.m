%Copyright (c) 2009, Bruno Luong
%All rights reserved.

%Redistribution and use in source and binary forms, with or without
%modification, are permitted provided that the following conditions are
%met:

%* Redistributions of source code must retain the above copyright
%notice, this list of conditions and the following disclaimer.
%* Redistributions in binary form must reproduce the above copyright
%notice, this list of conditions and the following disclaimer in
%the documentation and/or other materials provided with the distribution

%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%POSSIBILITY OF SUCH DAMAGE.


function [lower upper] = MergeBrackets(left, right)
% function [lower upper] = MergeBrackets(left, right)
%
% Purpose: Interval merging
%
% Given N input closed intervals in braket form:
%   Ii := [left(i),right(i)], i = 1,2...,N (mathematical notation)
% The set union{Ii) can be written as a canonical partition by
%   intervals Jk; i.e., union{Ii) = union(Jk), where Jk are M intervals
%   (with M<=N, so the partition is minimum cardinal), and {Jk} are
%   disjoint to each other (their intersections are empty). This function
%   returns Jk = [lower(k),upper(k)], k=1,2,...M, in the ascending sorted
%   order.
%
% EXAMPLE USAGE:
%   >> [lower upper] = MergeBrackets([0 1 2 3 4],[1.5 1.6 3.5 3 5])
%   	lower =   0    2  4
%       upper = 1.6  3.5  5
%
% Algorithm complexity: O(N*log(N))
%
% Author: Bruno Luong <brunoluong@yahoo.com>
% Original: 25-May-2009

% Detect when right < left (empty Ii), and later remove it (line #29, 30)
notempty = find(right>=left);

% sort the rest by left bound
[left iorder] = sort(left(notempty));
right = right(notempty(iorder));

% Allocate, as we don't know yet the size, we assume the largest case
lower = zeros(size(left));
upper = zeros(size(right));

% Nothing to do
if isempty(lower)
    return
end

% Initialize
l = left(1);
u = right(1);
k = 0;
% Loop on brakets
for i=1:length(left)
    if left(i) > u % new Jk detected
        % Stack the old one
        k = k+1;
        lower(k) = l;
        upper(k) = u;
        % Reset l and u
        l = left(i);
        u = right(i);
    else
        u = max(u, right(i));
    end
end % FOR loop
% Stack the last one
k = k+1;
lower(k) = l;
upper(k) = u;

% Remove the tails
lower(k+1:end) = [];
upper(k+1:end) = [];

end % MergeBrackets
