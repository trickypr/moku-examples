library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

architecture Behavioural of CustomWrapper is
begin
    BOX: entity WORK.BoxcarAverager
      port map (
        Clk, Reset, InputA, InputB, OutputA, OutputB
      );
end architecture;
