-----------------------------------------------------
-- 
-- Implementation of a simple Event Counter
-- counts events of PulseMin >= time > PulseMax (unit clks)
-- in periods of PeriodCounter_limit (unit clks)
-- If count > MinPulseCount then set OutA HI
-- OutB is invert of OutA
--
-- e.g. for pulses from min 48ns to max 99.2ns
-- Pulse_min = 0x0f
-- Pulse_max = 0x1f
-- PeriodCounter_limit = 0x0c35
-- MinPulseCount = 0x19
------------------------------------------------------


library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

library Moku;
use Moku.Support.sum_no_overflow;

architecture Behavioural of CustomWrapper is

    constant LO_LVL : signed(15 downto 0) := X"0000";
    constant HI_LVL : signed(15 downto 0) := X"7FFF";


    type CounterState is (
        WaitForEdge,
        TimeEvent,
        EventEnded,
        PeriodEnded
    );
    
    signal PeriodCounter_limit : unsigned(31 downto 0);
    signal Pulse_Min : unsigned(15 downto 0);
    signal Pulse_Max : unsigned(15 downto 0);
    signal Threshold : signed(15 downto 0);
    signal MinPulseCount : unsigned (15 downto 0);

    signal State : CounterState;
    signal NextState : CounterState;

    signal PeriodCounter : unsigned(31 downto 0);
    

    signal PulseCounter : unsigned(15 downto 0);
    signal PulseLenCounter  : unsigned(15 downto 0);

    signal Triggered : std_ulogic;
    signal Prev_Triggered : std_ulogic;
    signal Trigger_edge : std_ulogic;
    signal pulse_detected : std_ulogic;

    signal QuantumState0 : std_ulogic;
    
begin
  
    PeriodCounter_limit <= unsigned(Control1);
    Pulse_Min <= unsigned(Control2(15 downto 0));
    Pulse_Max <= unsigned(Control2(31 downto 16));
    Threshold <= signed(Control3(15 downto 0));
    MinPulseCount <= unsigned(Control3(31 downto 16));

    -- Period counter and pulse counter
    process(Clk) is
    begin
        if rising_edge(Clk) then
            if (Reset = '1') then
              PeriodCounter <= to_unsigned(0, 32);
              PulseLenCounter <= to_unsigned(0, 16);
              PulseCounter <= to_unsigned(0, 16);
            else
              if (PeriodCounter = PeriodCounter_limit) then
                PeriodCounter <= to_unsigned(0, 32);
              else
                PeriodCounter <= (PeriodCounter + 1);
              end if;
              
              if State = TimeEvent then
                PulseLenCounter <= PulseLenCounter +1;
              else
                PulseLenCounter <= to_unsigned(0, 16);
              end if;
              
              if (State = PeriodEnded) then
                PulseCounter <= to_unsigned(0, 16);
              elsif (State = EventEnded) and (pulse_detected = '1') then
                PulseCounter <= PulseCounter +1;
              end if;
            end if;
        end if;
    end process;
------------------------------------------------------------------------------
          
------------------------------------------------------------------------------
-- Trigger : detect both threshold and edge trigger
------------------------------------------------------------------------------
    process(Clk, Reset) is
    begin
        if (Reset = '1') then
          Triggered <= '0';
          Prev_Triggered <= '0';
        elsif rising_edge(Clk) then
          Triggered <= '1' when InputA > Threshold else '0';
          Prev_Triggered <= Triggered;         
        end if;
    end process;
    Trigger_edge <= NOT Prev_Triggered AND Triggered;

------------------------------------------------------------------------------
-- Move to next state
------------------------------------------------------------------------------
    process(Clk, Reset) is
    begin
        if (Reset = '1') then
          State <= WaitForEdge;
        elsif rising_edge(Clk) then
          State <= NextState;
        end if;
    end process;
------------------------------------------------------------------------------
          
------------------------------------------------------------------------------
-- Calculate next state
------------------------------------------------------------------------------
    process(State, PeriodCounter, Triggered, PulseLenCounter, PulseCounter)
    begin

        case State is
            when WaitForEdge =>
                if (PeriodCounter = PeriodCounter_limit) then
                  NextState <= PeriodEnded;
                elsif (Triggered = '1') then
                  NextState <= TimeEvent;
                else
                  NextState <= WaitForEdge;
                end if;
                pulse_detected <= '0';
           when TimeEvent =>
                if (PeriodCounter = PeriodCounter_limit) then
                  NextState <= PeriodEnded;
                elsif (Triggered = '1') then
                  NextState <= TimeEvent;
                else
                  NextState <= EventEnded;
                end if;
                pulse_detected <= '0';
            when EventEnded =>
                if (PeriodCounter = PeriodCounter_limit) then
                  NextState <= PeriodEnded;
                elsif (PulseLenCounter > pulse_min) and (PulseLenCounter < pulse_max) then
                  pulse_detected <= '1';
                  NextState <= WaitForEdge;
                else
                  pulse_detected <= '0';
                  NextState <= WaitForEdge;
                end if;

            when PeriodEnded =>
                if (PulseCounter >= MinPulseCount) then
                    QuantumState0 <= '1';
                else
                    QuantumState0 <= '0';
                end if;
                pulse_detected <= '0';
                NextState <= WaitForEdge;  
        end case;
    end process;

           
    OutputB <= HI_LVL when (QuantumState0 = '0') ELSE LO_LVL;                    
    OutputA <= HI_LVL when (QuantumState0 = '1') ELSE LO_LVL;
    
                  
end Behavioural;
------------------------------------------------------------------------------        

