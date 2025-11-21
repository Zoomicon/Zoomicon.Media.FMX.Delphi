unit Zoomicon.Media.FMX.SkiaUtils;

interface
  uses
    FMX.Objects, //for TImageWrapMode
    FMX.Skia; //for TSkSvgWrapMode, TSkAnimatedImageWrapMode

  function ImageWrapModeToSkSvg(AMode: TImageWrapMode): TSkSvgWrapMode;
  function ImageWrapModeToSkAnimated(AMode: TImageWrapMode): TSkAnimatedImageWrapMode;

  function InlineSvgStyle(const SvgText: string): string; //fix for SKIA not supporting SVG style classes

implementation
  uses
    System.Generics.Collections, //for TDictionary<KeyType,ValueType>
    System.StrUtils, //for PosEx
    System.SysUtils, //for TStringSplitOptions
    FMX.Types; //for Log.d

  function ImageWrapModeToSkSvg(AMode: TImageWrapMode): TSkSvgWrapMode;
  begin
    case AMode of
      TImageWrapMode.Original: Result := TSkSvgWrapMode.Original;
      TImageWrapMode.Fit:      Result := TSkSvgWrapMode.Fit;
      TImageWrapMode.Stretch:  Result := TSkSvgWrapMode.Stretch;
      TImageWrapMode.Tile:     Result := TSkSvgWrapMode.Tile;
      TImageWrapMode.Center:   Result := TSkSvgWrapMode.OriginalCenter;
      TImageWrapMode.Place:    Result := TSkSvgWrapMode.Place;
    else
      Result := TSkSvgWrapMode.Default; // respect SVG control default
    end;
  end;

  function ImageWrapModeToSkAnimated(AMode: TImageWrapMode): TSkAnimatedImageWrapMode;
  begin
    case AMode of
      TImageWrapMode.Original: Result := TSkAnimatedImageWrapMode.Original;
      TImageWrapMode.Fit:      Result := TSkAnimatedImageWrapMode.Fit;
      TImageWrapMode.Stretch:  Result := TSkAnimatedImageWrapMode.Stretch;
      TImageWrapMode.Center:   Result := TSkAnimatedImageWrapMode.OriginalCenter;
      TImageWrapMode.Place:    Result := TSkAnimatedImageWrapMode.Place;
      //TImageWrapMode.Tile has no animated equivalent; fall through
    else
      Result := TSkAnimatedImageWrapMode.Fit; // respect TSkAnimatedImage default
    end;
  end;

  function InlineSvgStyle(const SvgText: string): string;
  begin
    // Copy input SVG into a working variable
    var ResultSvg := SvgText;

    // Entry log: capture original input for forensic trace
    // Log.d('InlineSvgStyle input: ' + SvgText);

    // Locate <style> block boundaries
    var StyleStart := Pos('<style>', ResultSvg);
    var StyleEnd := Pos('</style>', ResultSvg);

    // Proceed only if a valid style block is found
    if (StyleStart > 0) and (StyleEnd > StyleStart) then
    begin
      // Extract raw CSS content between <style> and </style>
      var StyleBlock := Copy(ResultSvg, StyleStart + Length('<style>'),
        StyleEnd - (StyleStart + Length('<style>')));

      // Dictionary to map class names to merged inline attributes
      var ClassMap: TDictionary<string, string> := TDictionary<string, string>.Create;
      try
        // Robust scan: parse successive ".selector{...}" segments across the entire style block
        var idx := 1;
        while idx <= Length(StyleBlock) do
        begin
          // Find start of selector
          var selStart := PosEx('.', StyleBlock, idx);
          if selStart = 0 then Break;

          // Find opening and closing braces
          var openBrace := PosEx('{', StyleBlock, selStart + 1);
          if openBrace = 0 then Break;
          var closeBrace := PosEx('}', StyleBlock, openBrace + 1);
          if closeBrace = 0 then Break;

          // Extract selector list and rule body
          var SelectorPart := Trim(Copy(StyleBlock, selStart, openBrace - selStart));
          var RuleBody := Copy(StyleBlock, openBrace + 1, closeBrace - openBrace - 1);

          // Advance index past this rule
          idx := closeBrace + 1;

          // Split grouped selectors like ".cls-2,.cls-3"
          var ClassNames := SelectorPart.Split([','], TStringSplitOptions.ExcludeEmpty);
          var Props := RuleBody.Split([';'], TStringSplitOptions.ExcludeEmpty);

          // Process each selector
          for var RawClass in ClassNames do
          begin
            var ClassName := Trim(RawClass);
            if ClassName.StartsWith('.') then Delete(ClassName, 1, 1); // remove leading dot

            var Existing := '';
            ClassMap.TryGetValue(ClassName, Existing); // merge with prior attributes if any

            // Process each CSS property
            for var Prop in Props do
            begin
              var Parts := Prop.Split([':'], TStringSplitOptions.ExcludeEmpty);
              if Length(Parts) = 2 then
              begin
                var Name := Trim(Parts[0]);
                var Value := Trim(Parts[1]);

                // Expand shorthand stroke: "stroke: red 2px dashed"
                if Name = 'stroke' then
                begin
                  var StrokeParts := Value.Split([' '], TStringSplitOptions.ExcludeEmpty);
                  if Length(StrokeParts) > 0 then Existing := Existing + ' stroke="' + StrokeParts[0] + '"';
                  if Length(StrokeParts) > 1 then Existing := Existing + ' stroke-width="' + StrokeParts[1] + '"';
                  if Length(StrokeParts) > 2 then Existing := Existing + ' stroke-dasharray="' + StrokeParts[2] + '"';
                end
                // Map supported properties directly to inline attributes
                else if (Name = 'fill') or (Name = 'stroke-width') or
                        (Name = 'fill-opacity') or (Name = 'stroke-opacity') or
                        (Name = 'stroke-linecap') or (Name = 'stroke-linejoin') or
                        (Name = 'stroke-dasharray') or (Name = 'fill-rule') or
                        (Name = 'font-family') or (Name = 'font-size') or
                        (Name = 'font-weight') then
                  Existing := Existing + ' ' + Name + '="' + Value + '"';
              end;
            end;

            // Store merged attributes for this class
            ClassMap.AddOrSetValue(ClassName, Trim(Existing));
            // Log.d('ClassMap[' + ClassName + '] = ' + ClassMap[ClassName]);
          end;
        end;

        // Replace each class="..." in SVG with inline attributes
        var ScanPos := 1;
        while ScanPos < Length(ResultSvg) do
        begin
          // Find next class="..." occurrence
          var PosClass := PosEx('class="', ResultSvg, ScanPos);
          if PosClass = 0 then Break;

          // Extract class name between quotes
          var StartPos := PosClass + Length('class="');
          var EndPos := StartPos;
          while (EndPos <= Length(ResultSvg)) and (ResultSvg[EndPos] <> '"') do Inc(EndPos);
          var ClassName := Copy(ResultSvg, StartPos, EndPos - StartPos);

          // Replace or remove based on dictionary lookup
          if ClassMap.ContainsKey(ClassName) then
          begin
            var InlineAttrs := ClassMap[ClassName];

            ResultSvg := Copy(ResultSvg, 1, PosClass - 1) + InlineAttrs +
                         Copy(ResultSvg, EndPos + 1, Length(ResultSvg) - EndPos);

            // Log.d('Replaced class="' + ClassName + '" with: ' + InlineAttrs);
          end
          else
          begin
            ResultSvg := Copy(ResultSvg, 1, PosClass - 1) +
                         Copy(ResultSvg, EndPos + 1, Length(ResultSvg) - EndPos);

            // Log.d('Removed class="' + ClassName + '" (no matching style)');
          end;

          // Advance scan position to continue parsing
          ScanPos := PosClass + 1;
        end;

        // Remove the original <style> block entirely
        Delete(ResultSvg, StyleStart, StyleEnd + Length('</style>') - StyleStart);

      finally
        // Guaranteed cleanup: free dictionary and nil reference
        FreeAndNil(ClassMap);
      end;
    end;

    // Exit log: capture final transformed SVG
    // Log.d('InlineSvgStyle output: ' + ResultSvg);

    // Return transformed SVG
    Result := ResultSvg;
  end;

end.
