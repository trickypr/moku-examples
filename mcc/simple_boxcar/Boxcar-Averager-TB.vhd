library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

entity testbench is
-- empty
end testbench; 

architecture tb of testbench is

-- DUT component
component BoxcarAverager is
port(
  Clk:  in std_logic;
  Reset: in std_logic;
  ADC0: in signed (15 downto 0);
  ADC1: in signed (15 downto 0);
  DAC0: out signed (15 downto 0);
  DAC1: out signed (15 downto 0));
end component;

signal ADC0_in: signed (15 downto 0) := (others => '0');
signal ADC1_in: signed (15 downto 0) := (others => '0');
signal DAC0_out: signed (15 downto 0) := (others => '0');
signal DAC1_out: signed (15 downto 0) := (others => '0');
signal Clk: std_logic := '0';
signal Reset: std_logic := '1';

begin
  -- Connect DUT
  DUT: BoxcarAverager port map(Clk, Reset, ADC0_in, ADC1_in, DAC0_out, DAC1_out);
  
  Clk <= not Clk after 1 ns;
  Reset <= '0' after 5 ns;
  
  process
  begin
  	wait for 10 ns;
    ADC1_in <= to_signed(3000, ADC0_in'length);
    ADC0_in <= to_signed(64,ADC1_in'length);
    wait for 20 ns;
    ADC0_in <= to_signed(0, ADC0_in'length);
    wait for 50 ns;
    ADC1_in <= to_signed(0, ADC0_in'length);

  end process;
  
  process
  begin
  wait for 1000 ns;
  std.env.finish;
  end process;
  

  
end tb;
