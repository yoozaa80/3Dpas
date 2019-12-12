(*
**  Low-level 2D Graphics Library
**
**  Unit GraphDevice
**  Complete graphics device I/O implementation
**
**  6 Sep 98 - ndc - created.
**
**  Notes:
**  DC = device coordinates (device - pixels)
**  NDC = normal device coordinates (range 0..1 - lx, ly)
**      example: in 640x480 the point(0.5, 0.5) in NDC = 320, 240 pixels (DC)
**  WDC = world device coordinates (range unlimited)
**      example: in 10m x 6m the point(5, 5) in WDC = 0.5, 0.8333 (NDC)
**
**  window = the window on screen (in NDC)
**  viewport = the visible rect in WDC
*)

Unit GrDev;	(* 8 letters for DOS (unit = filename) *)

Interface

(* RectType, rectangle *)
Type RectType = Record
    l, t, r, b : Real; (* (l)eft, (t)op, (r)ight, (b)ottom *)
	end;

(* ColorType, color *)
Type ColorType = Record
    r, g, b : Real;	(* red, green, blue - range 0.0 .. 1.0 *)
    devColor : Integer;	(* hidden property - the device color (COLORREF or/and HPEN for Windows) *)
	end;

(* PenType, the pen *)
Type PenType = Record
    color : ColorType;	(* the color *)
	width : Real;			(* width in WDC *)
	end;

(* WindowType, window *)
Type WindowType = Record
		dc    : RectType;	(* coordinates (in NDC) *)
		wdc   : RectType;	(* world coordinates *)
		view  : RectType;	(* view-port (in WDC) *)

		Isotropic  : Boolean;	(* x/y correction *)
		IsotropicL : Real;		(* x/y correction *)

		(* HIDDEN *)
		drc	: RectType;   (* the window in DC *)
		lx, ly : Real;    (* wdc->dc *)
		sx, sy : Real;    (* origin *)
	end;

Procedure gdInitDevice;		(* Initialization *)
Procedure gdCloseDevice;	(* Close unit *)

Function  gdGetMaxPen : Integer;
Procedure gdSetPenData(pen : Integer; pen_data : PenType);
Procedure gdGetPenData(pen : Integer; VAR pen_data : PenType);
Function  gdGetSelectedPen : Integer;					(* Returns the current pen number *)

Procedure gdMakeRect(x1, y1, x2, y2 : Real; VAR rect : RectType);

Procedure NdcToDC(wx, wy : Real; VAR dev_x : Integer; VAR dev_y : Integer);
Procedure WdcToDC(wx, wy : Real; VAR dev_x : Integer; VAR dev_y : Integer);

Procedure gdSetWindow(index : Integer; VAR win : WindowType);
Procedure gdSelectWindow(index : Integer);
Procedure gdClearWindow;

Procedure gdSelectPen(Pen : Integer);				(* Select pen *)
Procedure gdLine(x1, y1, x2, y2 : Real);			(* Draw line *)
Procedure gdRect(rc : RectType);					(* Draw rectangle *)
Procedure gdText(x, y : Real; text : String);		(* Draw text *)
Function  gdTextHeight(text : String) : Real;		(* Returns the height of the text in WDC *)
Function  gdTextWidth (text : String) : Real;		(* Returns the width of the text in WDC *)

Implementation
(* --- Υλοποίηση --- *)

Uses Graph;

Const MaxPen = 15;	(* The maximum number of pens *)
Const MaxWin = 7;	(* The maximum number of windows *)

Var
	devCoords	: RectType;	(* minimum/maximum device coordinates *)
	world		: RectType;	(* minimum/maximum world(user) coordinates *)
	view		: RectType;	(* minimum/maximum viewport coordinates (wdc) *)

	pens		: Array [0 .. MaxPen] of PenType;	(* array of pens *)

	wins		: Array [0 .. MaxWin] of WindowType; (* array of windows *)

	curr_pen	: Integer;	(* Current pen number *)
	curr_win	: Integer;	(* Current window number *)

	dev_lxy		: Real;		(* device x/y *)

	n2d_lx, n2d_ly : Real;	(* NDC->DC *)
	w2d_lx, w2d_ly : Real;	(* WDC->DC *)
	w2d_sx, w2d_sy : Real;	(* WDC->DC starting pos *)

(*
**	Error handling - displays the message 'msg' and exits
*)
Procedure gdError(msg : String);
Begin
	CloseGraph;
	WriteLn('GraphDevice fatal error:');
	WriteLn(msg);
	Halt(1);	(* Fatal error - quit *)
End;

(*
**	Initialize module
*)
Procedure gdInitDevice;
Var
	bgiDriver, bgiMode, bgiError : Integer;
	i : Integer;
	pen_data : PenType;
	white_color : ColorType;
	default_window : WindowType;

Begin

	(* initialize device driver *)

	bgiDriver := Detect;
	InitGraph(bgiDriver, bgiMode, '');
	bgiError := GraphResult;
	
	If bgiError <> grOK Then Begin
		WriteLn('GraphDevice::InitGraph failed.');
		WriteLn('Graphics driver error: ', GraphErrorMsg(bgiError));
		Halt(1);        (* fatal error - program exit *)
		End;

	(* initialize global variables *)
	
	devCoords.l := 0;
	devCoords.t := 0;
	devCoords.r := GetMaxX;
	devCoords.b := GetMaxY;

	dev_lxy := (devCoords.r - devCoords.l) / (devCoords.b - devCoords.t);

	n2d_lx := (devCoords.r - devCoords.l);
	n2d_ly := devCoords.b - devCoords.t;

	(* initialize pens *)
	
	white_color.r := 1;
	white_color.g := 1;
	white_color.b := 1;
	white_color.devColor := 15;
	{ gdMakeColor(white_color); (* change palette color *) }

	For i := 0 to MaxPen do
		Begin
			(* ... I must make colors first ... *)
			white_color.devColor := MaxPen - i;
			pen_data.color := white_color;

			pen_data.width := 0.1;
			gdSetPenData(i, pen_data);
		End;

	gdSelectPen(0);

	(* initialize windows *)

	gdMakeRect(0, 0, 1, 1, default_window.dc);
	gdMakeRect(0, 0, 1, 1, default_window.wdc);
	gdMakeRect(0, 0, 1, 1, default_window.view);

	For i := 0 to MaxWin do
		gdSetWindow(i, default_window);

	gdSelectWindow(0);
End;

(*
**	Release allocated memory, and restores the crt mode.
*)
Procedure gdCloseDevice;
Begin
	CloseGraph;
End;

(*
**	fills the rect with the values x1..y2
*)
Procedure gdMakeRect(x1, y1, x2, y2 : Real; VAR rect : RectType);
Begin
	rect.l := x1;
	rect.r := x2;
	rect.t := y1;
	rect.b := y2
End;

(*
**	Converts coordinates from NDC to DC (Normal Device Coordinates TO Device Coordinates)
*)
Procedure NdcToDC(wx, wy : Real; VAR dev_x : Integer; VAR dev_y : Integer);
Begin
	dev_x := round(wx * n2d_lx);
	dev_y := round(wy * n2d_ly)
End;

(*
**	Converts coordinates from WDC to DC (World Device Coordinates TO Device Coordinates)
*)
Procedure WdcToDC(wx, wy : Real; VAR dev_x : Integer; VAR dev_y : Integer);
Begin
	dev_x := round(wx * w2d_lx + w2d_sx);
	dev_y := round(wy * w2d_ly + w2d_sy)
End;

(*
*)
Procedure gdSetWindow(index : Integer; VAR win : WindowType);
Var	x, y	: Integer;
Begin
	if (index >= 0) and (index <= MaxWin) then
		Begin
			NdcToDC(win.dc.l, win.dc.t, x, y);
			win.drc.l := x; 		win.drc.t := y;

			NdcToDC(win.dc.r, win.dc.b, x, y);
			win.drc.r := x;		win.drc.b := y;

			if	( win.Isotropic )	then
				Begin
					win.IsotropicL := (win.drc.r - win.drc.l) / (win.drc.b - win.drc.t);
					win.view.r :=	win.view.l 
									+ (win.view.b - win.view.t)
									* win.IsotropicL;
				End;

			(* wdc->dc l *)
			win.lx := (win.drc.r - win.drc.l) / (win.view.r - win.view.l); 
			win.ly := (win.drc.b - win.drc.t) / (win.view.b - win.view.t);

			(* wdc->dc starting pos *)
			win.sx := -win.view.l * win.lx (* + win.drc.l *);
			win.sy := -win.view.t * win.ly (* + win.drc.t *);

			wins[index] := win
		End
	else
		gdError('gdSetWindow: index out of range');
End;

(*
*)
Procedure gdSelectWindow(index : Integer);
Begin
	if (index >= 0) and (index <= MaxWin) then
		Begin
			w2d_lx := wins[index].lx;
			w2d_ly := wins[index].ly;

			w2d_sx := wins[index].sx;
			w2d_sy := wins[index].sy;

			curr_win := index;
			SetViewPort(	Round(wins[index].drc.l),
								Round(wins[index].drc.t),
								Round(wins[index].drc.r), 
								Round(wins[index].drc.b), 
								True);
		End
	else
		gdError('gdSelectWindow: index out of range');
End;

(*
**	Returns the maximum number of supported pens
*)
Function gdGetMaxPen : Integer;
Begin
	gdGetMaxPen := MaxPen;
End;

(*
**	Sets the pen data
*)
Procedure gdSetPenData(pen : Integer; pen_data : PenType);
Begin
	if (pen >= 0) and (pen <= MaxPen) then
		pens[pen] := pen_data
	else
		gdError('SetPen: pen out of range.');
End;

(*
**	Returns the pen data
*)
Procedure gdGetPenData(pen : Integer; VAR pen_data : PenType);
Begin
	if (pen >= 0) and (pen <= MaxPen) then
		pen_data := pens[pen]
	else
		gdError('GetPen: pen out of range.');
End;

(*
**	Selects the current pen (current color)
*)
Procedure gdSelectPen(pen : Integer);
Begin
	curr_pen := pen;

	SetColor(pens[curr_pen].color.devColor);
End;

(*
*)
Function	gdGetSelectedPen : Integer;
Begin
	gdGetSelectedPen := curr_pen;
End;

(*
**	draw a line
*)
Procedure gdLine(x1, y1, x2, y2 : Real);
Var
	dev_x1, dev_x2, dev_y1, dev_y2 : Integer;

Begin
	WdcToDC(x1, y1, dev_x1, dev_y1);
	WdcToDC(x2, y2, dev_x2, dev_y2);

	Line(dev_x1, dev_y1, dev_x2, dev_y2);
End;

(*
**	draw a rectangle
*)
Procedure gdRect(rc : RectType);
Begin
	gdLine(rc.l, rc.t, rc.r, rc.t);
	gdLine(rc.l, rc.t, rc.l, rc.b);
	gdLine(rc.r, rc.b, rc.l, rc.b);
	gdLine(rc.r, rc.b, rc.r, rc.t)
End;

(*
**	draw text
*)
Procedure gdText(x, y : Real; text : String);
Var
	dev_x, dev_y : Integer;
Begin
	WdcToDC(x, y, dev_x, dev_y);
	dev_y := dev_y + 1;	(* +1 pixel for spacing *)
	OutTextXY(dev_x, dev_y, text);
End;

(*
**	Returns the height of the text in WDC
*)
Function  gdTextHeight(text : String) : Real;
Var	h : Word;
Begin
	h := TextHeight(text) + 2;	(* +2 pixels for spacing *)
	gdTextHeight := h * 1.0 / w2d_ly;
End;

(*
**	Returns the width of the text in WDC
*)
Function  gdTextWidth(text : String) : Real;
Var	w : Word;
Begin
	w := TextWidth(text);
	gdTextWidth := w * 1.0 / w2d_lx;
End;

(*
*)
Procedure gdClearWindow;
Begin
	ClearViewPort;
End;

End.
