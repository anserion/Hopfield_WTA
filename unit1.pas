(*
------------------------------------------------------------------
Copyright 2019
Andrey S. Ionisyan (anserion@gmail.com)
Aleksey V. Shaposhnikov (ashaposhnikov@ncfu.ru)
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
------------------------------------------------------------------
*)

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Grids;

type

  { TForm1 }

  TForm1 = class(TForm)
    BTN_learn: TButton;
    BTN_clk: TButton;
    BTN_random_images: TButton;
    BTN_random_X0: TButton;
    CB_tanh: TCheckBox;
    CB_WTA: TCheckBox;
    EDIT_m: TEdit;
    EDIT_n: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    SG_images: TStringGrid;
    SG_S_discrete: TStringGrid;
    SG_w_discrete: TStringGrid;
    SG_y_cont: TStringGrid;
    SG_w_cont: TStringGrid;
    SG_S_cont: TStringGrid;
    SG_y_discrete: TStringGrid;
    SG_X0: TStringGrid;
    procedure BTN_clkClick(Sender: TObject);
    procedure BTN_learnClick(Sender: TObject);
    procedure BTN_random_imagesClick(Sender: TObject);
    procedure BTN_random_X0Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SG_X0EditingDone(Sender: TObject);
  private
    procedure refresh_visual;
    procedure recreate_grids;
  public

  end;

var
  Form1: TForm1;

  clk: integer; // элементарный шаг работы нейросети Хопфилда
  N: integer;   //число нейронов сети Хопфилда
  M: integer;   //число образов-эталонов внутри сети Хопфилда
  X0:array[0..255] of integer; //входной нейизвестный образ
  X:array[0..255,0..255] of integer; //образы-эталоны

  W_cont: array[0..255,0..255] of real; //весовые коэффициенты непрерывной сети
  s_cont: array[0..255]of real; //выход скалярного произведения непрерывной сети
  y_cont: array[0..255] of real; //выходы нейронов непрерывной сети

  W_discrete: array[0..255,0..255] of integer; //весовые коэффициенты дискретной сети
  S_discrete: array[0..255]of integer; //выход скалярного произведения дискретной сети
  y_discrete: array[0..255] of integer; //выходы нейронов дискретной сети


implementation

{$R *.lfm}

{ TForm1 }

//пересоздание элементов графического пользовательского интерфейса
procedure TForm1.recreate_grids;
var i:integer;
begin
  clk:=0;

  M:=StrToInt(EDIT_m.text);
  N:=StrToInt(EDIT_n.text);

  SG_X0.RowCount:=2;
  SG_X0.ColCount:=N+1;

  SG_images.RowCount:=M+1;
  SG_images.ColCount:=N+1;

  SG_W_cont.RowCount:=N+1;
  SG_W_cont.ColCount:=N+1;

  SG_W_discrete.RowCount:=N+1;
  SG_W_discrete.ColCount:=N+1;

  SG_S_cont.RowCount:=2;
  SG_S_cont.ColCount:=N+1;

  SG_S_discrete.RowCount:=2;
  SG_S_discrete.ColCount:=N+1;

  SG_y_cont.RowCount:=2;
  SG_y_cont.ColCount:=N+1;

  SG_y_discrete.RowCount:=2;
  SG_y_discrete.ColCount:=N+1;

  SG_X0.Cells[0,1]:='X=';

  SG_S_cont.Cells[0,1]:='S=';
  SG_S_discrete.Cells[0,1]:='S=';

  SG_y_cont.Cells[0,1]:='Y=';
  SG_y_discrete.Cells[0,1]:='Y=';

  for i:=1 to m do SG_images.Cells[0,i]:=IntToStr(i-1);

  for i:=1 to n do
     begin
          SG_X0.Cells[i,0]:=IntToStr(i-1);

          SG_images.Cells[i,0]:=IntToStr(i-1);

          SG_W_cont.Cells[i,0]:=IntToStr(i-1);
          SG_W_cont.Cells[0,i]:=IntToStr(i-1);

          SG_W_discrete.Cells[i,0]:=IntToStr(i-1);
          SG_W_discrete.Cells[0,i]:=IntToStr(i-1);

          SG_S_cont.Cells[i,0]:=IntToStr(i-1);
          SG_y_cont.Cells[i,0]:=IntToStr(i-1);

          SG_S_discrete.Cells[i,0]:=IntToStr(i-1);
          SG_y_discrete.Cells[i,0]:=IntToStr(i-1);
     end;
end;

//отображение содержимого таблиц работы нейронной сети Хопфилда
procedure TForm1.refresh_visual;
var i,j:integer;
begin
  for i:=0 to m-1 do
     for j:=0 to n-1 do
         SG_images.Cells[j+1,i+1]:=IntToStr(X[i,j]);

  for i:=0 to n-1 do
     for j:=0 to n-1 do
     begin
        SG_W_cont.Cells[j+1,i+1]:=FloatToStr(W_cont[i,j]);
        SG_W_discrete.Cells[j+1,i+1]:=IntToStr(W_discrete[i,j]);
     end;

  for i:=0 to n-1 do
     begin
          SG_X0.Cells[i+1,1]:=IntToStr(X0[i]);

          SG_S_cont.Cells[i+1,1]:=FloatToStr(s_cont[i]);
          SG_y_cont.Cells[i+1,1]:=FloatToStr(y_cont[i]);

          SG_S_discrete.Cells[i+1,1]:=IntToStr(S_discrete[i]);
          SG_y_discrete.Cells[i+1,1]:=IntToStr(y_discrete[i]);
     end;

  BTN_clk.caption:='Шаг работы нейросети ('+intToStr(clk)+')';
end;

//обработка элементарного шага работы нейронной сети Хопфилда
procedure TForm1.BTN_clkClick(Sender: TObject);
var i,j:integer; //счетчики циклов
    g:integer;  //номер победившего WTA-нейрона
    max_out:integer; //скалярное произведение победившего WTA-нейрона
    async:integer; //случайно выбранный нейрон асинхронной работы сети Хопфилда
begin
  //если первый шаг работы сети, то скопировать неизвестный сигнал в выход
  //и обнулить скалярные произведения сети Хопфилда
  if clk=0 then
  begin
    for i:=0 to n-1 do X0[i]:=StrToInt(SG_X0.Cells[i+1,1]);
    for i:=0 to n-1 do
       begin
            y_cont[i]:=X0[i];
            s_cont[i]:=0;

            y_discrete[i]:=X0[i];
            s_discrete[i]:=0;
       end;
    clk:=1;
  end
  else //для последующих шагов работы сети Хопфилда
  begin
       //обработка модели непрерывной сети Хопфилда
       for j:=0 to n-1 do
       begin
            async:=random(n);
            s_cont[async]:=0;
            for i:=0 to n-1 do s_cont[async]:=s_cont[async]+w_cont[i,async]*y_cont[i];
            if CB_tanh.checked
            then y_cont[async]:=(exp(2*s_cont[async])-1)/(exp(2*s_cont[async])+1)
            else
            begin
                 if s_cont[j]>0 then y_cont[j]:=1;
                 if s_cont[j]<0 then y_cont[j]:=-1;
            end;
       end;
       //---------------------------------

       //обработка модели дискретной сети Хопфилда
       for j:=0 to n-1 do
       begin
            async:=random(n);
            S_discrete[async]:=0;
            for i:=0 to n-1 do S_discrete[async]:=S_discrete[async]+w_discrete[i,async]*y_discrete[i];
            if S_discrete[async]>0 then y_discrete[async]:=1;
            if S_discrete[async]<0 then y_discrete[async]:=-1;
       end;
       //реализация алгоритма WTA
       if CB_WTA.checked then
       begin
            max_out:=-1; g:=0;
            for i:=0 to n-1 do
            if (abs(S_discrete[i])>max_out) and (S_discrete[i]*y_discrete[i]<0) then
            begin
                 max_out:=abs(S_discrete[i]);
                 g:=i;
            end;
            if max_out>0 then y_discrete[g]:= -y_discrete[g];
       end;
       //---------------------------------

       clk:=clk+1;
  end;
  refresh_visual;
end;

//алгоритм обучения (расчета весовых коэффициентов) сети Хопфилда
procedure TForm1.BTN_learnClick(Sender: TObject);
var i,j,k:integer;
begin
  recreate_grids;

  //загрузка образов-эталонов
  for i:=0 to m-1 do
     for j:=0 to n-1 do
         if SG_images.Cells[j+1,i+1]<>''
         then X[i,j]:=StrToInt(SG_images.Cells[j+1,i+1])
         else X[i,j]:= -1;
  //---------------------------------

  //расчет коэффициентов непрерывной модели сети Хопфилда
  for i:=0 to n-1 do
  begin
       for j:=0 to n-1 do
       begin
            W_cont[i,j]:=0;
            if i<>j then
               for k:=0 to m-1 do W_cont[i,j]:=W_cont[i,j]+X[k,i]*X[k,j];
            W_cont[i,j]:=W_cont[i,j]/n;
       end;
       s_cont[i]:=0;
       y_cont[i]:=0;
  end;
  //---------------------------------

  //расчет коэффициентов дискретной модели сети Хопфилда
  for i:=0 to n-1 do
  begin
       for j:=0 to n-1 do
       begin
            W_discrete[i,j]:=0;
            if i<>j then
               for k:=0 to m-1 do W_discrete[i,j]:=W_discrete[i,j]+X[k,i]*X[k,j];
       end;
       S_discrete[i]:=0;
       y_discrete[i]:=0;
  end;
  //---------------------------------

  refresh_visual;
end;

//генерация случайных образов-эталонов и обучение сети Хопфилда
procedure TForm1.BTN_random_imagesClick(Sender: TObject);
var i,j:integer;
begin
  recreate_grids;
  for i:=0 to m-1 do
  for j:=0 to n-1 do
  begin
      X[i,j]:=random(2);
      if x[i,j]=0 then x[i,j]:=-1;
  end;
  refresh_visual;
  BTN_learnClick(self);
end;

//генерация случайного входного "неизвестного" образа
procedure TForm1.BTN_random_X0Click(Sender: TObject);
var i:integer;
begin
  for i:=0 to n-1 do
  begin
       X0[i]:=random(2);
       if X0[i]=0 then X0[i]:=-1;
  end;
  clk:=0;
  refresh_visual;
end;

//инициализация программы
procedure TForm1.FormCreate(Sender: TObject);
var j:integer;
begin
  N:=4; Edit_n.text:=IntToStr(N);
  M:=2; Edit_m.text:=IntToStr(M);
  recreate_grids;

  for j:=0 to 255 do X0[j]:=-1;

  for j:=0 to n-1 do X[0,j]:=-1;
  for j:=0 to n-1 do X[1,j]:=1;

  refresh_visual;

  BTN_learnClick(self);
end;

//сброс шагов работы нейросети Хопфилда при любой модификации входного сигнала
procedure TForm1.SG_X0EditingDone(Sender: TObject);
begin
  clk:=0;
end;

end.

