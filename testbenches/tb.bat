@echo off
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
set path=c:\tools\ghdl\bin;c:\tools\ghdl-0.35\bin;C:\tools\mingw-w64\x86_64-8.1.0-posix-seh-rt_v6-rev0\mingw64\bin;C:\tools\mingw-w64\msys2_64\usr\bin
echo UARTRX
ghdl -a --ieee=synopsys --std=08 ..\rtl\UARTRX.vhdl
if errorlevel == 1 goto error
echo Analyze TB
ghdl -a --ieee=synopsys --std=08 UARTRX_tb.vhdl
if errorlevel == 1 goto error
echo Elaborate phase
ghdl -e --ieee=synopsys --std=08 UARTRX_tb
echo Run simulation
if errorlevel == 1 goto error
ghdl -r --ieee=synopsys --std=08 UARTRX_tb --vcd=UARTRX_tb.vcd --stop-time=40us
:error
