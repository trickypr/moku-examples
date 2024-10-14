LIBRARY IEEE;
USE IEEE.Std_Logic_1164.ALL;
USE IEEE.Numeric_Std.ALL;

-- This code here stores the data for each point coming off an oscilloscope.
-- The rate of data entry is determined by the Input_Data_Downsampling value, which acts as a direct decimator factor on the incoming data.

-- The data is double-buffered for triggering, with a separate output buffer.

-- Trigger is set for Rising edge

ENTITY Data_Block IS
    GENERIC (
        H_Display : INTEGER;
        V_Display : INTEGER
    );
    PORT (
        --Input
        Data_Clock : IN STD_LOGIC;
        Input_Data : IN signed(15 DOWNTO 0);
        Input_Data_Downsampling : IN unsigned(31 DOWNTO 0);
        H_counter : IN unsigned(15 DOWNTO 0);
        --Output
        Output_Value : OUT signed(8 DOWNTO 0)
    );
END Data_Block;

ARCHITECTURE structure OF Data_Block IS

    ------------------------------------------
    TYPE DATA_ARRAY_SCREEN IS ARRAY (0 TO H_Display) OF signed(8 DOWNTO 0); --Defining the array
    SIGNAL R_Data : DATA_ARRAY_SCREEN; --Display Read Array
    SIGNAL W1_Data : DATA_ARRAY_SCREEN; --Display Write1 Array
    SIGNAL W2_Data : DATA_ARRAY_SCREEN; --Display Write2 Array

    SIGNAL Array_Address_counter : unsigned(15 DOWNTO 0); --Array Wrapping
    SIGNAL Input_Data_Clock : unsigned(31 DOWNTO 0); --Downsampling clock
    SIGNAL Input_Data_norm : signed(15 DOWNTO 0);

    SIGNAL Current_Buffer : STD_LOGIC;
    SIGNAL Trig : STD_LOGIC;
    SIGNAL Input_Data_Previous : signed(15 DOWNTO 0);

    ------------------------------------------

BEGIN

    PROCESS (Data_Clock)
    BEGIN

        IF rising_edge(Data_Clock) THEN

            ------------------------------------------
            --We need to limit the H_counter to the display array to read data in Array
            IF H_counter < H_Display - 1 THEN
                Output_Value <= R_Data(to_integer(H_counter)); --Reading new data
            ELSE
                -- Once we leave the display area it's safe to update the output buffer. We do this with a huge latch in one clock cycle, we have the gates for it!
                IF Current_Buffer = '1' THEN
                    FOR I IN 0 TO H_Display LOOP
                        R_Data(I) <= W1_Data(I); --W1 map
                    END LOOP;
                ELSE
                    FOR I IN 0 TO H_Display LOOP
                        R_Data(I) <= W2_Data(I); --w2 map
                    END LOOP;
                END IF;
            END IF;
            ------------------------------------------

            --Variable period between samples  
            IF Input_Data_Clock < Input_Data_Downsampling THEN
                Input_Data_Clock <= Input_Data_Clock + 1;
            ELSE
                Input_Data_Clock <= (OTHERS => '0');
                Input_Data_Previous<=Input_Data; --Writing to previous for rising edge.

                IF Trig = '1' THEN --Clock cycles for data storage for buf1

                    --Wrapping Array Addresses 
                    IF (Array_Address_counter < H_Display - 1) THEN
                        Array_Address_counter <= Array_Address_counter + 1;
                    ELSE
                        Array_Address_counter <= (OTHERS => '0');

                        --Only does rising edge when signal is fast enough that you cannot see it via scanning.
                        IF Input_Data_Downsampling < 30000 THEN
                            Current_Buffer <= NOT(Current_Buffer); --cycling buffer (once per frame)
                            Trig <= '0'; --Reset trig (once per frame).
                        ELSE
                            Current_Buffer <= '1'; --Never resets, only runs on one of the registers.
                            Trig <= '1';
                        END IF;

                    END IF;

                    --Begin trigger process 
                    Input_Data_norm <= shift_left(Input_Data, 4);
                    IF Current_Buffer = '1' THEN
                        W1_Data(to_integer(Array_Address_counter)) <= Input_Data_norm(15 DOWNTO 7); --Writing new data
                    ELSE
                        W2_Data(to_integer(Array_Address_counter)) <= Input_Data_norm(15 DOWNTO 7); --Writing new data                                  
                    END IF;

                ELSE 
                    --When Trig='0' we check to see if the rising edge has started. If so, we begin measuring the data.
                    IF Input_Data > 0  and Input_Data_Previous < 0 THEN
                        Trig <= '1';
                    END IF;
                
                END IF; --Wrapping Trig if

            END IF; --Variable period if

        END IF; --rising edge if

    END PROCESS;

END structure;
