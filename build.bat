@echo off
setlocal enabledelayedexpansion

set DFLAGS=-version=DIP61 -O -release -inline
set CORE=
set STD=
set STDD=
set ANALYSIS=

for %%x in (*.d) do set CORE=!CORE! %%x
for %%x in (std/*.d) do set STD=!STD! std/%%x
for %%x in (std/d/*.d) do set STDD=!STDD! std/d/%%x
for %%x in (analysis/*.d) do set ANALYSIS=!ANALYSIS! analysis/%%x

@echo on
dmd %CORE% %STD% %STDD% %ANALYSIS% %DFLAGS% -ofdscanner.exe

