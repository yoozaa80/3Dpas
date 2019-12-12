(*
**	Κεντρική εφαρμογή
*)
Program View3D(input, output);

(* units (βιβλιοθήκες) to load *)
Uses grdev, gr3d, crt;

(* Μερικές σταθερές *)
Const MenuWinIndex = 0;
Const DesignWinIndex = 1;

(* Μέγιστος αριθμός [γραφικών] στοιχείων *)
Const MaxItem = 255;

(* Είδη στοιχείων *)
Type DrawItemCode   = ( Line2D, Line3D );
Type DrawItemValues = Array [1..6] of Real;

(* Τελικός ορισμός του 3Δ στοιχείου *)
Type DrawItemType = Record
	Code : DrawItemCode;	(* είδος στοιχείου *)
	Vals : DrawItemValues;	(* παράμετροι *)
	end;

(* Gobal μεταβλητές *)
Var
	MenuWindow : WindowType;
	DrawWindow : WindowType;

	items : Array [0..MaxItem] of DrawItemType;
	itemCount : Integer;

	(* 3D vals *)
	x_angle, z_angle : Real;
	depth, dist : Real;

(*
**	Αρχικοποίηση, initialization of graphics driver
**	and default values to global variables.
*)
Procedure InitProg;
Begin
	gdInitDevice;

	(* Το παράθυρο για το μενού (σε NDC) *)
	MenuWindow.dc.l := 0;
	MenuWindow.dc.r := 0.16;
	MenuWindow.dc.t := 0;
	MenuWindow.dc.b := 1;	(* the window on screen (in NDC) *)
	MenuWindow.Isotropic := False;

	MenuWindow.wdc := MenuWindow.dc;	(* the world of the window *)
	MenuWindow.view := MenuWindow.wdc; (* the viewport of the window *)

	gdSetWindow(MenuWinIndex, MenuWindow);

	(* the window for the design (in NDC) *)
	DrawWindow.dc.l := 0.16;
	DrawWindow.dc.r := 1;
	DrawWindow.dc.t := 0;
	DrawWindow.dc.b := 1;
	DrawWindow.Isotropic := True;

	(* Create a world 10m x 10m *)
	gdMakeRect(-5, -5, 5, 5, DrawWindow.wdc);
	(* Set viewport to entire world *)
	DrawWindow.view := DrawWindow.wdc;

	gdSetWindow(DesignWinIndex, DrawWindow);
End;

(*
**	Clean-up
*)
Procedure CloseProg;
Begin
	gdCloseDevice;
End;

(*
**	Προσθήκη ενός γραφικού στοιχείου στον πίνακά μας
*)
Procedure AddItem(Code : DrawItemCode; Vals : DrawItemValues);
Begin
	if (itemCount > MaxItem) or (itemCount < 0) then
    	Begin
        WriteLn('Item list overflow');
		Halt(1);
		End;
	items[itemCount].Code := Code;
	items[itemCount].Vals := Vals;
	itemCount := itemCount + 1;
End;

(*
*)
Procedure	DrawMenu;
Var
	ySize : Real;
	y 		: Real;
Begin
	gdSelectWindow(MenuWinIndex);
	gdRect(MenuWindow.wdc);

	y := 0.01;
	ySize := gdTextHeight('M');	

	gdText(0.01, y, 'Menu');	y := y + ySize;
	gdText(0.01, y, 'goes');	y := y + ySize;
	gdText(0.01, y, 'here');	y := y + ySize;
	gdText(0.01, y, '----');	y := y + ySize;
	gdText(0.01, y, 'A,Z Move U/D');	y := y + ySize;
	gdText(0.01, y, '<,> Move L/R');	y := y + ySize;
	gdText(0.01, y, '------------');	y := y + ySize;
	gdText(0.01, y, 'LEFT,RIGHT');	y := y + ySize;
	gdText(0.01, y, '   Rotate X');	y := y + ySize;
	gdText(0.01, y, 'UP,DOWN');		y := y + ySize;
	gdText(0.01, y, '   Rotate Z');	y := y + ySize;
	gdText(0.01, y, '------------');	y := y + ySize;
	gdText(0.01, y, 'P,p Depth');		y := y + ySize;
	gdText(0.01, y, 'D,d Distance');		y := y + ySize;
End;

(*
*)
Procedure	DrawDesign;
Var	i : Integer;
	r : RectType;
	x1, y1, x2, y2, yText, ySize : Real;
	tmp_str : String[40];
	res : String;

Begin
	gdSelectWindow(DesignWinIndex);
	gdClearWindow;
	gdRect(DrawWindow.view);

	(* draw axes *)

	gdSelectPen(14);
	g3CalcPoint(0, 0, 0, x1, y1);

	g3CalcPoint(10, 0, 0, x2, y2);
	gdLine(x1, y1, x2, y2);
	g3CalcPoint(1.5, 0, 0, x2, y2);
	gdText(x2, y2, 'x');

	g3CalcPoint(0, 10, 0, x2, y2);
	gdLine(x1, y1, x2, y2);
	g3CalcPoint(0, 1.5, 0, x2, y2);
	gdText(x2, y2, 'y');

	g3CalcPoint(0, 0, 10, x2, y2);
	gdLine(x1, y1, x2, y2);
	g3CalcPoint(0, 0, 1.5, x2, y2);
	gdText(x2, y2, 'z');

	(* draw items *)

	gdSelectPen(0);
	For i := 0 to itemCount - 1 do
		Begin
			if (items[i].Code = Line2D) then
				gdLine(items[i].Vals[1], items[i].Vals[2], items[i].Vals[3], items[i].Vals[4])
			else if (items[i].Code = Line3D) then
				Begin
					g3CalcPoint(items[i].Vals[1], items[i].Vals[2], items[i].Vals[3], x1, y1);
					g3CalcPoint(items[i].Vals[4], items[i].Vals[5], items[i].Vals[6], x2, y2);
					gdLine(x1, y1, x2, y2);
				End;
		End;

	(* draw info *)

	ySize := gdTextHeight('M');	
	yText := DrawWindow.view.b - ySize * 6;

	Str((x_angle * 180.0/PI):4:3, tmp_str);
	res := ' Angle X  = ' + tmp_str;
	gdText(DrawWindow.view.l + 0.01, yText, res);	yText := yText + ySize;

	Str((z_angle * 180.0/PI):4:3, tmp_str);
	res := ' Angle Z  = ' + tmp_str;
	gdText(DrawWindow.view.l + 0.01, yText, res);	yText := yText + ySize;

	Str(dist:4:3, tmp_str);
	res := ' Distance = ' + tmp_str;
	gdText(DrawWindow.view.l + 0.01, yText, res);	yText := yText + ySize;

	Str(depth:4:3, tmp_str);
	res := ' Depth    = ' + tmp_str;
	gdText(DrawWindow.view.l + 0.01, yText, res);	yText := yText + ySize;

	g3GetVPCoords(x1, y1, x2);
	Str(x1:4:3, tmp_str);
	res := ' ViewPoint=(' + tmp_str;
	Str(y1:4:3, tmp_str);
	res := res + ', ' + tmp_str;
	Str(x2:4:3, tmp_str);
	res := res + ', ' + tmp_str + ')';
	gdText(DrawWindow.view.l + 0.01, yText, res);	yText := yText + ySize;
End;

(*
	Waits a key - for debuging (unit crt needed)
*)
Procedure Pause;
Var	ch : Char;
Begin
	ch := ReadKey;
	if ch = #27 then
		Halt(1);
End;

(*
**	Περιμένει να πατηθεί ένα πλήκτρο και επιστρέφει
**	τον κωδικό του.
*)
Function GetKey : Integer;
Var	ch : Char;
Begin
	ch := ReadKey;
	if ch = #0 then
		GetKey := 1000 + Ord(ReadKey)
	else
		GetKey := Ord(ch);
End;

(*
**	Σβήνει τα κενά από την αρχή και το τέλος του 'text'.
**	Επιστρέφει το καινούριο string.
*)
Function Trim(text : String) : String;
Var	i, len	: Integer;
	ch		: Char;
	start, ends : Integer;
Begin
	len := Length(text);
	If len = 0 Then
		Trim := ''
	Else begin
		start := 1;
		While (text[start] = ' ') and (start < len) Do
			start := start + 1;

		If (start >= len) and (text[len] = ' ') Then
			Trim := ''
		Else begin
			ends := len;
			While (text[ends] = ' ') and (ends > 1) do
				ends := ends - 1;
			Trim := Copy(text, start, (ends - start) + 1)
			End;
		End;
End;

(*
**	Μετατροπή του 'src' σε πραγματικό αριθμό.
**	Επιστρέφει στο dst την αριθμητική τιμή.
**	Επιστρέφει το κείμενο...
*)
Function GetRealWord(src : String; VAR dst : Real) : String;
Var
	l, i, e	: Integer;
	ch		: Char;
	strx	: String;

Begin
	l := Length(src);
	For i := 1 to l do
		Begin
		ch := src[i];
		if (ch = ',') or (ch = ';') then
			Begin
			strx := Copy(src, 1, i-1);
			strx := Trim(strx);
			Val(strx, dst, e);
			if (ch = ';') then
				GetRealWord := ''
			else
				GetRealWord := Copy(src, i + 1, (l - i));
			Exit;
			End;
		End;
End;

(*
**	Read a v3d file
*)
Procedure ReadV3D(filename : String);
Var
	f		: Text;
	textLine : String;
	cmd		: String;
	remain	: String;
	par		: DrawItemValues;
	line_num : Integer;
	len, i	: Integer;

Begin
	Assign(f, filename);
	Reset(f);
	line_num := 1;
	While NOT EOF(f) do begin
		ReadLn(f, textLine);
		line_num := line_num + 1;
		len := Length(textLine);

		If len > 3 then begin
			if	( textLine[1] <> '#' ) then (* αν δεν είναι comment *)
				Begin
				cmd := Copy(textLine, 1, 3);
				remain := Copy(textLine, 4, Length(textLine) - 3);
				if	cmd = 'ln2' then	(* Line2D *)
					Begin
					For i := 1 to 4 do
						remain := GetRealWord(remain, par[i]);
					AddItem(Line2D, par);
					End
				else if	cmd = 'ln3' then	(* Line3D *)
					Begin
					For i := 1 to 6 do
						remain := GetRealWord(remain, par[i]);
					AddItem(Line3D, par);
					End
				else begin
					WriteLn('File: ', filename, ' @', line_num);
					WriteLn('Unknown command: ', textLine);
					Halt(1);
					End;
				End;
			End
		Else begin
			WriteLn('Syntax error @', line_num);
			Halt(1);
			End;
		End;
	Close(f);
End;

(*
*)
Function Menu : Boolean;
Var
	Code : Integer;
	xMove, yMove : Real;
	angle_inc	 : Real;
	dist_inc, depth_inc : Real;

Begin
	Menu := True;
	xMove := 1;	(* 1m *)
	yMove := 1;	(* 1m *)
	angle_inc := 5.0 * Pi / 180.0;
	dist_inc := 1;
	depth_inc := 1;

	code := GetKey;
	Case code of
	27:
		Menu := False;
	60, 44:	(* < - move left *)
		Begin
			DrawWindow.view.l :=	DrawWindow.view.l + xMove;
			DrawWindow.view.r :=	DrawWindow.view.r + xMove;
			gdSetWindow(DesignWinIndex, DrawWindow);
		End;
	62, 46:	(* > - move right *)
		Begin
			DrawWindow.view.l :=	DrawWindow.view.l - xMove;
			DrawWindow.view.r :=	DrawWindow.view.r - xMove;
			gdSetWindow(DesignWinIndex, DrawWindow);
		End;
	90, 122:	(* Z - move down *)
		Begin
			DrawWindow.view.t :=	DrawWindow.view.t - yMove;
			DrawWindow.view.b :=	DrawWindow.view.b - yMove;
			gdSetWindow(DesignWinIndex, DrawWindow);
		End;
	65, 97:	(* A - move up *)
		Begin
			DrawWindow.view.t :=	DrawWindow.view.t + yMove;
			DrawWindow.view.b :=	DrawWindow.view.b + yMove;
			gdSetWindow(DesignWinIndex, DrawWindow);
		End;
	1075:		(* left - rotate X *)
		Begin
			x_angle := x_angle + angle_inc;
			g3SetVPAngles(x_angle, z_angle);
		End;
	1077:		(* right - rotate X *)
		Begin
			x_angle := x_angle - angle_inc;
			g3SetVPAngles(x_angle, z_angle);
		End;
	1072:		(* up - rotate Z *)
		Begin
			z_angle := z_angle - angle_inc;
			g3SetVPAngles(x_angle, z_angle);
		End;
	1080:		(* down - rotate Z *)
		Begin
			z_angle := z_angle + angle_inc;
			g3SetVPAngles(x_angle, z_angle);
		End;
	68:		(* D - distance *)
		Begin
			dist := dist - dist_inc;
			g3SetVPDist(dist);
		End;
	100:		(* d - distance *)
		Begin
			dist := dist + dist_inc;
			g3SetVPDist(dist);
		End;
	80:		(* P - depth *)
		Begin
			depth := depth - depth_inc;
			g3SetVPDepth(depth);
		End;
	112:		(* p - depth *)
		Begin
			depth := depth + depth_inc;
			g3SetVPDepth(depth);
		End;
	End;
End;

(*
**	Κεντρικό πρόγραμμα
*)
Begin
	(* Αν έχει παράμετρο αρχείο, διάβασέ το *)
	itemCount := 0;
	if ParamCount > 0 then
		ReadV3D(ParamStr(1));

	(* αρχικοποίηση *)
	InitProg;
	depth := 15;
	dist := 10;
	g3SetVPDist(dist);
	g3SetVPDepth(depth);
	x_angle := Pi / 4.0;
	z_angle := Pi / 4.0;
	g3SetVPAngles(x_angle, z_angle);

	(* σχεδιασμός παραθύρου μενού *)
	DrawMenu;

	(* επανέλαβε μέχρι να ζητήσει ο χρήστης να φύγει *)
	Repeat
		DrawDesign;
	Until (Menu = False);

	(* κλείσιμο όλων *)
	CloseProg;
End.
