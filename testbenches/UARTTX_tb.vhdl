
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UARTTX_tb is

end UARTTX_tb;

architecture logic of UARTTX_tb is
    component HP75_top is 
        port (
            clk_in          : in std_logic;                     -- sync clock
            clk_16kHz_in    : in std_logic;                     -- rtc clock
            reset_in        : in std_logic;                     -- asserted high reset
            dump_lcd_in     : in std_logic;                     -- 
            use_trace_in    : in std_logic;						-- trace enable
            key_cols_in     : in std_logic_vector(7 downto 0);  -- colmn inputs
            key_rows_o      : out std_logic_vector(7 downto 0); -- row outputs
            key_attn_in     : in std_logic;                     -- attn key
            mem_data_in     : in std_logic_vector(7 downto 0);  -- memory data input
            mem_data_o      : out std_logic_vector(7 downto 0); -- memory data output to memory or I/O
            mem_addr_o      : out std_logic_vector(15 downto 0);-- memory address
            mem_page_o      : out std_logic_vector(3 downto 0); -- page hwen addressing 8000..9F000
            mem_rd_o        : out std_logic;                    -- read strobe, asserted high
            mem_we_o        : out std_logic                     -- write strobe, asserted high
    );
    end component HP75_top;
         
    signal    clk             : std_logic := '0'; -- clock
    signal    clk_16kHz       : std_logic := '0'; -- RTC clock
    signal    dump_lcd        : std_logic := '0'; -- dump the contents of the LCD buffer
    signal    reset           : std_logic := '0'; -- active high reset
    signal    key_cols        : std_logic_vector(7 downto 0) := X"00";           -- keyboard column signal
    signal    key_rows        : std_logic_vector(7 downto 0);           -- keyboard rows, output
    signal    key_attn        : std_logic := '1';                    -- keyboard active row
    signal    mem_data_in     : std_logic_vector(7 downto 0); -- reg_data_to_periph
    signal    mem_data_o      : std_logic_vector(7 downto 0); -- reg_data_to_periph
    signal    mem_addr        : std_logic_vector(15 downto 0); -- Register address
    signal    mem_page        : std_logic_vector(3 downto 0); -- Peripheral address
    signal    mem_rd          : std_logic;                    -- read strobe
    signal    mem_we          : std_logic;                    -- write strobe
    
begin

    
    hp75 : HP75_top port map(
        clk_in          => clk,          
        clk_16kHz_in    => clk_16kHz,               -- rtc clock
        reset_in        => reset,
        dump_lcd_in     => dump_lcd,
        use_trace_in    => '1',						-- trace enable
		key_cols_in     => key_cols,        
        key_rows_o      => key_rows,          
        key_attn_in     => key_attn,          
        mem_data_in     => mem_data_in,
        mem_data_o      => mem_data_o,
        mem_addr_o      => mem_addr,
        mem_page_o      => mem_page,
        mem_rd_o        => mem_rd,
        mem_we_o        => mem_we
    );
    
    process 
        begin
            clk        <= '0';
            wait for 500 ns;
            clk        <= '1';
            wait for 500 ns;
        end process;
    -- RTC clock
    process 
        begin
            clk_16kHz  <= '0';
            wait for 61035 ns;
            clk_16kHz  <= '1';
            wait for 61035 ns;
        end process;

    process 
        begin
            reset        <= '1';
            wait for 2233 ns;
            reset        <= '0';
            wait;
        end process;
        
    process 
        begin
            wait for 400 ms;
            key_cols     <= "00000001";
            wait for 17 ms;
            key_cols     <= "00000000";
            wait;
        end process;
        
end architecture logic;




