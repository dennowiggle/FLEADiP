-- Uses the Digilent "ssd pmod" module which is a two digit seven segment display.
-- Written as part of the VHDLWhiz course "FPGA and VHDL Fast-Track:"
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sevenSegTimer is
    generic(
        clk_hz          : integer := 12e6;
        alt_counter_len : integer := 16
    );
    port (
        clk             : in std_logic;
        rst_n           : in std_logic;
        segments        : out std_logic_vector(6 downto 0);
        digit_sel       : out std_logic
    );
end sevenSegTimer;

architecture rtl of sevenSegTimer is

    -- Internal reset
    signal rst                  : std_logic;

    -- Shift register for generating the internal reset
    signal shift_reg            : std_logic_vector(7 downto 0);

    -- Binary-coded decimal
    -- a subtype is based on an existing type (in this case integer)
    subtype digit_type is integer range 0 to 9;
    signal digit                : digit_type;
    type digits_type is array (0 to 1) of digit_type;
    signal digits               : digits_type;

    -- For timing the 7-seg counting
    -- uncomment to speed up 10x
    -- constant tick_counter_max : integer := clk_hz / 10 - 1;
    constant tick_counter_max   : integer := clk_hz - 1;
    signal   tick_counter       : integer range 0 to tick_counter_max;
    signal   tick               : std_logic;

    -- Counter for alternating between 1 and 10's digit
    -- 12e6 MHz  / (2 ** 16) = 183.1 Hz refresh rate
    signal alt_counter          : unsigned(alt_counter_len - 1 downto 0);

    -- Finite-state machine (FSM)
    type bcd_state_type is (COUNT_ONES, COUNT_TENS);
    signal bcd_state            : bcd_state_type;

    -- function incr_wrap(d : digit_type) return digit_type is
    --   begin
    --     if d = 9 then 
    --       return 0;
    --     else 
    --       return d + 1;
    --     end if;
    --   end function;
        procedure incr_wrap(signal d : inout digit_type) is
        begin
            if d = 9 then 
                d <= 0;
            else 
                d <= d + 1;
            end if;
        end procedure;
        

    begin

    
    BCD_FSM_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                digits <= (others => 0);
                bcd_state <= COUNT_ONES;
            else

                if tick = '1' then
                    incr_wrap(digits(0));
                end if;

                case bcd_state is
                
                when COUNT_ONES =>
                    if digits(0) = 9 then
                        bcd_state <= COUNT_TENS;
                    end if;
                    
                when COUNT_TENS =>
                    if tick = '1' then
                        incr_wrap(digits(1));

                        bcd_state <= COUNT_ONES;
                    end if;
                
                end case;

            end if;
        end if;
    end process;


    ALTERNATE_COUNTER_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                alt_counter <= (others => '0');
            else
                alt_counter <= alt_counter + 1;
            end if;
        end if;
    end process;

    OUTPUT_MUX_PROC : process(alt_counter)
    begin
        -- Check the highest bit in the index
        if alt_counter(alt_counter'high) = '1' then
            digit <= digits(1);
            digit_sel <= '0';
        else
            digit <= digits(0);
            digit_sel <= '1';
        end if;
    end process;

    TICK_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tick_counter <= 0;
                tick <= '0';
            else
                if tick_counter = tick_counter_max then
                    tick_counter <= 0;
                    tick <= '1';
                else
                    tick_counter <= tick_counter + 1;
                    tick <= '0';
                end if;
                
            end if;
        end if;
    end process;

    SHIFT_REG_PROC : process(clk)
    begin
        if rising_edge(clk) then
            shift_reg <= shift_reg(6 downto 0) & rst_n;
        end if;
    end process;

    RESET_PROC : process(shift_reg)
    begin
        if shift_reg = "11111111" then
            rst <= '0';
        else
            rst <= '1';
        end if;
    end process;
    
    ENCODER_PROC : process(digit)
        -- Segments from the PmodSSD datasheet
        constant A : integer := 0;
        constant B : integer := 1;
        constant C : integer := 2;
        constant D : integer := 3;
        constant E : integer := 4;
        constant F : integer := 5;
        constant G : integer := 6;
    begin
        segments <= (others => '1');
        case digit is
    
        when 0 =>
            segments(G) <= '0';
    
        when 1 =>
            segments <= (others => '0');
            segments(E) <= '1';
            segments(F) <= '1';
    
        when 2 =>
            segments(C) <= '0';
            segments(F) <= '0';
    
        when 3 =>
            segments(B) <= '0';
            segments(C) <= '0';
    
        when 4 =>
            segments(A) <= '0';
            segments(D) <= '0';
            segments(B) <= '0';
    
        when 5 =>
            segments(B) <= '0';
            segments(E) <= '0';
    
        when 6 =>
            segments(E) <= '0';
    
        when 7 =>
            segments(A) <= '0';
            segments(B) <= '0';
            segments(C) <= '0';
            segments(G) <= '0';
    
        when 8 =>
    
        when 9 =>
            segments(B) <= '0';
    
        when others =>
            segments <= (others => '0');
    
        end case;
    end process;
end architecture;