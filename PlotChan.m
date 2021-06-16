function [plotH dataObj] = PlotChan(selDir, selChan, startT, winT, varargin)
%% PlotChan
% Plots data associated with a particular channel

%% Syntax
%# [plotH dataObj] = PlotChan(selDir, selChan, startT, winT)

%% Description
% Plots the time series and event data associated with a particular channel
% during the specfied time window.

%% INPUT
% * selDir - a string, the directory containing the data
% * selChan - an integer scalar, the channel to be plotted
% * startT - an scalar, the starting time point for the sampling window
% * winT - a scalar, the duration of the sampling windows

%% OUTPUT
% * plotH - a structure with the handle for the figure and each trace
% * dataObj - a structure with the data used to plot

%% Example

%% Executable code