library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity NeonBlast is
	Port(
		--//////////// CLOCK //////////
		CLOCK_24 	: in std_logic;
		
		--//////////// KEY //////////
		RESET_N	: in std_logic;
		
		
		--//////////// VGA //////////
		VGA_B		: out std_logic_vector(1 downto 0);
		VGA_G		: out std_logic_vector(1 downto 0);
		VGA_HS	: out std_logic;
		VGA_R		: out std_logic_vector(1 downto 0);
		VGA_VS	: out std_logic;
		
		--//////////// KEYS //////////
		Key : in std_logic_vector(3 downto 0);
		SW : in std_logic_vector(7 downto 0);
		
		--//////////// LEDS //////////
		Leds : out std_logic_vector(7 downto 0);
		
		--////////////Segments////////
		outseg         : out bit_vector(3 downto 0); --Enable of segments to choose one
		sevensegments  : out bit_vector(7 downto 0)
	);
end NeonBlast;

--}} End of automatically maintained section

architecture NeonBlast of NeonBlast is

Component VGA_controller
	port ( CLK_24MHz		: in std_logic;
         VS					: out std_logic;
			HS					: out std_logic;
			RED				: out std_logic_vector(1 downto 0);
			GREEN				: out std_logic_vector(1 downto 0);
			BLUE				: out std_logic_vector(1 downto 0);
			RESET				: in std_logic;
			ColorIN			: in std_logic_vector(5 downto 0);
			ScanlineX		: out std_logic_vector(10 downto 0);
			ScanlineY		: out std_logic_vector(10 downto 0)
  );
end component;

Component VGA_Square
	port ( CLK_24MHz		: in std_logic;
			RESET				: in std_logic;
			Btn          : in std_logic_vector(3 downto 0);
			end_game       : in bit;
			pause				: in bit;	
			score          : out integer;
			lose           : out bit;
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			random : in integer range 0 to 24000000;
			ScanlineY		: in std_logic_vector(10 downto 0)
  );
end component;

  signal ScanlineX,ScanlineY	: std_logic_vector(10 downto 0);
  signal ColorTable	: std_logic_vector(5 downto 0);
  signal seg0: bit_vector(7 downto 0):=x"C6";
  signal seg1: bit_vector(7 downto 0):=x"88";
  signal seg2: bit_vector(7 downto 0):=x"c0";
  signal seg3: bit_vector(7 downto 0):=x"A4"; -- CAD2 = CAD1402 
  signal seg_selectors : BIT_VECTOR(3 downto 0) := "1110" ;
  signal timer_game,best_time : Integer range 0 to 100 :=0;
  signal end_game,pause : bit :='0';
  signal score,best_score : integer:=0;
  signal lose: bit ;
  signal leds_signal : std_logic_vector(7 downto 0) := "10101010";
  signal rand : integer range 0 to 24000000 :=0;
	type segcode is array (0 to 9) of bit_vector(7 downto 0);
	constant codeseg : segcode :=(x"c0",x"F9",x"A4",x"B0",x"99",x"92",x"82",x"F8",x"80",x"98");
  begin
	 --------- VGA Controller -----------
	 VGA_Control: vga_controller
			port map(
				CLK_24MHz	=> CLOCK_24,
				VS				=> VGA_VS,
				HS				=> VGA_HS,
				RED			=> VGA_R,
				GREEN			=> VGA_G,
				BLUE			=> VGA_B,
				RESET			=> not RESET_N,
				ColorIN		=> ColorTable,
				ScanlineX	=> ScanlineX,
				ScanlineY	=> ScanlineY
			);
		
		--------- Moving Square -----------
		VGA_SQ: VGA_Square
			port map(
				CLK_24MHz		=> CLOCK_24,
				RESET				=> not RESET_N,
				Btn          => Key,
				end_game			=> end_game,
				pause				=> pause,
				score          => score,
				lose           => lose,
				ColorOut			=> ColorTable,
				SQUAREWIDTH		=> "00010101",
				ScanlineX		=> ScanlineX,
				random			=> rand,
				ScanlineY		=> ScanlineY
			);
	 
	 --change selector to choose one of segments each time
	 process(CLOCK_24) 
	 variable counter : integer range 0 to 5000 :=0;
	 begin
		 if(rising_edge(CLOCK_24)) then 
			 counter := counter +1;
			 if (counter = 4999) then 
				 counter :=0;
			    seg_selectors <= seg_selectors(0) & seg_selectors(3 downto 1);
			 end if;
		 end if;
	 end process;
	 process(CLOCK_24,RESET_N) 
	 variable flag_key :bit:= '0';
	 variable flag_rst :bit:= '0';
	 variable counter : integer range 0 to 24000000 :=0;
	 begin
	    if RESET_N = '0' then
		 flag_key := '0';
		 flag_rst := '1';
		 counter := 0;
		 timer_game <= 0;
		 elsif(rising_edge(CLOCK_24)) then 
			if(SW(0) = '0') then pause <='0';
			else pause <= '1'; end if;
		  if( key(0) = '0' and flag_rst = '1')then
	      flag_key := '1';
		  end if;
	     if (flag_key = '1' and pause = '0') then
			 counter := counter +1;
			 if (counter = 23999999) then 
				 counter :=0;
				if( end_game = '1') then
					timer_game <= timer_game;
				else
					timer_game <= timer_game+1;
			 end if;
			 end if;
			 end if;
		 end if;
		 rand <= counter;
	 end process;
	 
	 process( timer_game )
	 begin
		if(timer_game = 60 OR lose = '1')then
			if(score > best_score) then
				best_score <= score;
				best_time <= timer_game;
			end if;
			end_game <= '1';
		else
		   end_game <= '0';
		end if;
	 end process;
  
   process(RESET_N,CLOCK_24 )
	variable flag_rst: bit := '0';
	variable timer_leds : integer range 0 to 12000001 := 0;
	begin
	if RESET_N = '0' then
	   flag_rst := '1';
		leds <= "00000000";
		leds_signal <= "10101010";
		timer_leds := 0;
	elsif(rising_edge(CLOCK_24 )) then
	   timer_leds := timer_leds + 1;
    	if flag_rst = '1' and end_game = '1' then
		   leds <= "11111111";
		elsif flag_rst = '1' and end_game = '0' and timer_leds = 12000000  then
		   leds_signal <= leds_signal(0) & leds_signal (7 downto 1);
			leds <= leds_signal;
		end if;
	end if;
	end process;
	
   outseg <= seg_selectors;
	 
	 process(seg_selectors,seg0,seg1,seg2,seg3 )
	 begin
		case seg_selectors is
			when "1110" =>
			sevenSegments <= seg0;
			when "0111" =>
			sevenSegments <= seg3;
			when "1011" =>
			sevenSegments <= seg2;
			when "1101" =>
			sevenSegments <= seg1;
			when others =>
			sevenSegments <= x"c0";
		end case;
	end process;
	
   process( RESET_N,CLOCK_24 )
	variable flag_key :bit:= '0';
	begin
	if RESET_N = '0' then
			seg0 <= x"f9";
			seg1 <= x"B0";
		 	seg2 <= x"f9";
	    	seg3 <= x"f9";
			flag_key := '0';
	elsif(rising_edge(CLOCK_24)) then 
	if( key(0) = '0' or key(1) = '0' )then
	      flag_key := '1';
	end if;
	if ((flag_key = '1' and end_game = '0') or key(2) = '0') then
		seg3 <= codeseg(score mod 10);
		seg2 <= codeseg(score / 10);
		seg1 <= codeseg(timer_game mod 10);
		seg0 <= codeseg(timer_game / 10);
	elsif(sw(1) = '1') then
		seg3 <= codeseg(best_score mod 10);
		seg2 <= codeseg(best_score / 10);
		seg1 <= codeseg(best_time mod 10);
		seg0 <= codeseg(best_time / 10);
	elsif(lose='1') then
		seg0 <= x"c7";
		seg1 <= x"c0";
		seg2 <= x"92";
	   seg3 <= x"86";  
	elsif(timer_game >= 60) then
	   seg0 <= x"92";
	   seg1 <= x"c1";
		seg2 <= x"c6";
	   seg3 <= x"c6";
	end if;
	end if;
end process;
	 
end NeonBlast;
