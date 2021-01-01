--
--
-- ADC example
--
-- For the MAX10
--
-- The internal ADC of the MAX10 is used to capture 1024 samples
-- on request, the values are then streamed to the UART at 1 MBit/s
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MAX10_ADC is
    port (
        ADC_CLK_10          : in std_logic;
        MAX10_CLK1_50       : in std_logic; -- only clock used
        MAX10_CLK2_50       : in std_logic;
        reset_in            : in std_logic;

        -- UART interface
        tx_o                : out std_logic;
        rx_in               : in std_logic;
        
        -- display interface (only for DE10-Lite board)
        HEX0                : out std_logic_vector(7 downto 0);
        HEX1                : out std_logic_vector(7 downto 0);
        HEX2                : out std_logic_vector(7 downto 0);
        HEX3                : out std_logic_vector(7 downto 0);
        HEX4                : out std_logic_vector(7 downto 0);
        HEX5                : out std_logic_vector(7 downto 0)
        
    );
end MAX10_ADC;

architecture logic of MAX10_ADC is
    component PLL is 
        port (
		inclk0      : IN STD_LOGIC;
		c0          : OUT STD_LOGIC ; -- 10 MHz the first clock must be a 10 MHz clock on the PLL1
		c1          : OUT STD_LOGIC ; -- 12 MHz
		c2          : OUT STD_LOGIC ; -- 50 MHz
		c3          : OUT STD_LOGIC ; --  1 MHz
		locked      : OUT STD_LOGIC 
        );   
    end component PLL;
    component ADC is
	port (
		adc_pll_clock_clk      : in  std_logic                     := '0';             --  adc_pll_clock.clk
		adc_pll_locked_export  : in  std_logic                     := '0';             -- adc_pll_locked.export
		clock_clk              : in  std_logic                     := '0';             --          clock.clk
		command_valid          : in  std_logic                     := '0';             --        command.valid
		command_channel        : in  std_logic_vector(4 downto 0)  := (others => '0'); --               .channel
		command_startofpacket  : in  std_logic                     := '0';             --               .startofpacket
		command_endofpacket    : in  std_logic                     := '0';             --               .endofpacket
		command_ready          : out std_logic;                                        --               .ready
		reset_sink_reset_n     : in  std_logic                     := '0';             --     reset_sink.reset_n
		response_valid         : out std_logic;                                        --       response.valid
		response_channel       : out std_logic_vector(4 downto 0);                     --               .channel
		response_data          : out std_logic_vector(11 downto 0);                    --               .data
		response_startofpacket : out std_logic;                                        --               .startofpacket
		response_endofpacket   : out std_logic                                         --               .endofpacket
	);
    end component ADC;
    
    component UARTTX is
	port (
		clk_in      : in  std_logic; -- 50 MHz clock
		data_in     : in  std_logic_vector(7 downto 0);
		start_in    : in  std_logic;
        tx_busy_o   : out std_logic;       
		tx_o        : out std_logic                      
	);
    end component UARTTX;

    component UARTRX is
	port (
		clk_in      : in  std_logic; -- 50 MHz clock
		data_o      : out  std_logic_vector(7 downto 0);
		data_rdy_o  : out  std_logic;
		data_ovr_o  : out  std_logic;
        data_ack_in : in std_logic;
        bits_o      : out  std_logic_vector(7 downto 0);
		bit_cnt_o   : out  std_logic_vector(7 downto 0);
		rx_in       : in std_logic
	);
    end component UARTRX;


    component CLUT7SEG is
	port (
		digit_in    : in  std_logic_vector(3 downto 0);
		segs_o      : out std_logic_vector(7 downto 0)
	);
    end component CLUT7SEG;

    component ADCBuffer is
    port (
    	data        : in std_logic_vector(15 downto 0);
    	rdaddress   : in std_logic_vector(9 downto 0);
    	rdclock     : in std_logic;
    	wraddress   : in std_logic_vector(9 downto 0);
    	wrclock     : in std_logic;
    	wren        : in std_logic;
    	q           : out std_logic_vector(15 downto 0)
    );
    end component ADCBuffer;

    signal clk_10MHz    : std_logic;
    signal clk_12MHz    : std_logic;
    signal clk_50MHz    : std_logic;
    signal clk_1MHz     : std_logic;
    signal pll_locked       : std_logic; -- pll locked used as reset signal, reset active low
    signal tx_data      : std_logic_vector(7 downto 0);
    signal rx_data      : std_logic_vector(7 downto 0);
    signal tx_start     : std_logic;
    signal tx_busy      : std_logic;
    signal rx_ready     : std_logic;
    signal rx_overrun   : std_logic;
    signal rx_ack       : std_logic;
    signal bits         : std_logic_vector(7 downto 0);
    signal bit_cnt      : std_logic_vector(7 downto 0);
    signal d5           : std_logic_vector(3 downto 0);
    signal adc_pll_clock_clk      : std_logic;             --  adc_pll_clock.clk
    signal adc_pll_locked_export  : std_logic;             -- adc_pll_locked.export
    signal clock_clk              : std_logic;             --          clock.clk
    signal command_valid          : std_logic;             --        command.valid
    signal command_channel        : std_logic_vector(4 downto 0)  := (others => '0'); --               .channel
    signal command_startofpacket  : std_logic;             --               .startofpacket
    signal command_endofpacket    : std_logic;             --               .endofpacket
    signal command_ready          : std_logic;                                        --               .ready
    signal reset_sink_reset_n     : std_logic;             --     reset_sink.reset_n
    signal response_valid         : std_logic;                                        --       response.valid
    signal response_channel       : std_logic_vector(4 downto 0);                     --               .channel
    signal response_data          : std_logic_vector(11 downto 0);                    --               .data
    signal response_startofpacket : std_logic;                                        --               .startofpacket
    signal response_endofpacket   : std_logic;                                         --               .endofpacket

    signal data_to_buffer   : std_logic_vector(15 downto 0);
    signal buff_rd_addr_i   : integer range 0 to 2047 := 0;
    signal buff_rd_addr     : std_logic_vector(9 downto 0);
    
    signal buff_wr_addr_i   : integer range 0 to 2047 := 0;
    signal buff_wr_addr     : std_logic_vector(9 downto 0);

    signal buff_wr          : std_logic := '0';
    signal buff_data_out    : std_logic_vector(15 downto 0);
    signal buff_data_out_2  : std_logic_vector(15 downto 0);

    signal tx_state         : integer range 0 to 31 := 0;
    signal buff_state       : integer range 0 to 7 := 0;

    signal adc_state_50     : integer range 0 to 7 := 0;
    signal adc_state        : integer range 0 to 15 := 0;
    
    signal adc_timestamp    : integer range 0 to 65535 := 0;
    
    function to_shex( h : std_logic_vector(3 downto 0) ) return std_logic_vector is
        variable r: std_logic_vector(7 downto 0);
        variable i: integer range 0 to 15;
        
        begin
            i := to_integer(unsigned(h));
            case (i) is
                when  0 => r := X"30";
                when  1 => r := X"31";
                when  2 => r := X"32";
                when  3 => r := X"33";
                when  4 => r := X"34";
                when  5 => r := X"35";
                when  6 => r := X"36";
                when  7 => r := X"37";
                when  8 => r := X"38";
                when  9 => r := X"39";
                when 10 => r := X"41";
                when 11 => r := X"42";
                when 12 => r := X"43";
                when 13 => r := X"44";
                when 14 => r := X"45";
                when 15 => r := X"46";
            end case;
            return r;
    end function;

begin

    ipll : pll port map(
        inclk0  => MAX10_CLK1_50,      -- 50 MHz clock on the board
        c0      => clk_10MHz,
        c1      => clk_12MHz,
        c2      => clk_50MHz,
        c3      => clk_1MHz,
        locked  => pll_locked
        );
       
    rx_ack <= rx_ready;
    
    irx : UARTRX port map(
        clk_in      => clk_50MHz,
        data_o      => rx_data,
        data_rdy_o  => rx_ready,
        data_ovr_o  => rx_overrun,
        data_ack_in => rx_ack,
        bits_o      => bits,
		bit_cnt_o   => bit_cnt,
		
        rx_in       => rx_in
    );
        
        
    -- the ADC is configured for 1 MHz sampling but
    -- the timestamp reveals that it samples at 500 kHz 
    -- (100 clocks between samples)
    -- maybe the pll clock has to be rised to 20 or 40 MHz...
    command_channel <= "00001";
    reset_sink_reset_n <= '1';
    
    iADC : ADC 
	port map (
		adc_pll_clock_clk      => clk_10MHz,             --  adc_pll_clock.clk
		adc_pll_locked_export  => pll_locked,             -- adc_pll_locked.export
		clock_clk              => clk_50MHz,             --          clock.clk
		command_valid          => command_valid,         --        command.valid
		command_channel        => command_channel,       --               .channel
		command_startofpacket  => command_startofpacket, --               .startofpacket
		command_endofpacket    => command_endofpacket,   --               .endofpacket
		command_ready          => command_ready,         --               .ready
		reset_sink_reset_n     => reset_sink_reset_n,    --     reset_sink.reset_n
		response_valid         => response_valid,        --       response.valid
		response_channel       => response_channel,      --               .channel
		response_data          => response_data,         --               .data
		response_startofpacket => response_startofpacket,--               .startofpacket
		response_endofpacket   => response_endofpacket   --               .endofpacket
	);    
        
    
    -- Transfer of buffer memory via UART
    -- when a command is received, the buffer is sent
    --
    
    --tx_start <= rx_ready;
    -- tx_data <= rx_data;
    
    itx : UARTTX port map(
        clk_in      => clk_50MHz,
        data_in     => tx_data,
        start_in    => tx_start,
        tx_busy_o   => tx_busy,
        tx_o        => tx_o
    );

    data_to_buffer <= "0000" & response_data;
    buff_rd_addr <= std_logic_vector(to_unsigned(buff_rd_addr_i, 10));
    buff_wr_addr <= std_logic_vector(to_unsigned(buff_wr_addr_i, 10));
    
    iBuff : ADCBuffer port map(
    	data        => data_to_buffer,
    	rdaddress   => buff_rd_addr,
    	rdclock     => clk_50MHz,
    	wraddress   => buff_wr_addr,
    	wrclock     => clk_50MHz,
    	wren        => buff_wr,
    	q           => buff_data_out
    );
    -- store timestamps
    itimestamp : ADCBuffer port map(
    	data        => std_logic_vector(to_unsigned(adc_timestamp, 16)),
    	rdaddress   => buff_rd_addr,
    	rdclock     => clk_50MHz,
    	wraddress   => buff_wr_addr,
    	wrclock     => clk_50MHz,
    	wren        => buff_wr,
    	q           => buff_data_out_2
    );
    
    

    
    
    process(clk_50MHz) 
    begin
        if (rising_edge(clk_50MHz)) then
            tx_start <= '0';
            if rx_ready = '1' then
                -- wait for command
                if buff_state = 0 and rx_data = X"52" then -- 'R' Read
                    buff_state <= 1;
                    tx_state <= 0;
                    buff_rd_addr_i <= 0;
                end if;
                if adc_state_50 = 0 and rx_data = X"53" then -- 'S' sample
                    adc_state_50 <= 1;
                end if;
            end if;
            
            case buff_state is
                when 0 => null;
                when 1 => 
                    if buff_rd_addr_i = 1024 then
                        buff_state <= 0;
                    else
                        tx_state <= 1; -- start transmission 
                        buff_state <= 2;
                    end if;
                when 2 =>
                    if tx_state = 19 then
                        buff_rd_addr_i <= (buff_rd_addr_i + 1) mod 2048;
                        buff_state <= 1;
                        tx_state <= 0;
                    end if;
                when others => null;
            end case;
            case tx_state is
                when 0 => null;
                when 1 => -- sends first char
                    tx_data <= to_shex(buff_data_out_2(15 downto 12));
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 2 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 3 => -- sends first char
                    tx_data <= to_shex(buff_data_out_2(11 downto 8));
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 4 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 5 => -- sends 2nd char
                    tx_data <= to_shex(buff_data_out_2(7 downto 4));
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 6 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 7 => -- sends first char
                    tx_data <= to_shex(buff_data_out_2(3 downto 0));
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 8 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 9 => -- sends first char
                    tx_data <= X"3A";
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 10 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 11 => -- sends first char
                    tx_data <= to_shex(buff_data_out(11 downto 8));
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 12 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 13 => -- sends 2nd char
                    tx_data <= to_shex(buff_data_out(7 downto 4));
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 14 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 15 => -- sends first char
                    tx_data <= to_shex(buff_data_out(3 downto 0));
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 16 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                when 17 => -- sends CR char
                    tx_data <= X"0D";
                    tx_start <= '1';
                    if tx_busy = '1' then
                        tx_state <= tx_state + 1;
                    end if;
                when 18 => 
                    if tx_busy = '0' then
                        tx_state <= tx_state + 1;
                    end if;
                
                when others => null;
            end case;
            
            case adc_state_50 is
                when 0 => null;
                when 1 => 
                    if adc_state = 4 then
                        adc_state_50 <= 0;
                    end if;
                when others => null;
            end case;
        end if;
    end process;
    
    
    buff_wr <= response_valid;
    
    process(clk_50MHz) 
    begin
        if (rising_edge(clk_50MHz)) then
            adc_timestamp <= (adc_timestamp + 1) mod 65536;
            case adc_state is
                when 0 => 
                    adc_timestamp <= 0;
                    if adc_state_50 = 1 then
                        adc_state <= adc_state + 1;
                        buff_wr_addr_i <= 0;
                    end if;
                when 1 => 
                    -- start sampling
                    command_valid <= '1';
                    command_startofpacket <= '1';
                    adc_state <= adc_state + 1;
                when 2 =>
                    if command_ready = '1' then
                        command_startofpacket <= '0';
                        command_endofpacket <= '1';
                        adc_state <= adc_state + 1;
                    end if;
                when 3 =>
                    command_endofpacket <= '0';
                    if response_valid = '1' then
                        if buff_wr_addr_i = 1024 then
                            adc_state <= 4;
                        else
                            adc_state <= 1;
                            buff_wr_addr_i <= (buff_wr_addr_i + 1) mod 2048;
                        end if;
                    end if;
                when others => 
                    adc_state <= 0;
                    command_valid <= '0';
            end case;
        end if;
    end process;

        
    -- comment out when not using DE10-Lite
    h0 : CLUT7SEG port map(
        digit_in    => rx_data(7 downto 4),
        segs_o      => HEX1
    );

    h1 : CLUT7SEG port map(
        digit_in    => rx_data(3 downto 0),
        segs_o      => HEX0
    );

    h2 : CLUT7SEG port map(
        digit_in    => buff_wr_addr(3 downto 0),
        segs_o      => HEX2
    );

    h3 : CLUT7SEG port map(
        digit_in    => buff_wr_addr(7 downto 4),
        segs_o      => HEX3
    );
    
    h4 : CLUT7SEG port map(
        digit_in    => std_logic_vector(to_unsigned(adc_state_50, 4)),
        segs_o      => HEX4
    );

    d5 <= rx_ready & rx_overrun & '0' & tx_busy;
    
    h5 : CLUT7SEG port map(
        digit_in    => std_logic_vector(to_unsigned(adc_state, 4)), -- bit_cnt(7 downto 4),
        segs_o      => HEX5
    );
    
end architecture;
