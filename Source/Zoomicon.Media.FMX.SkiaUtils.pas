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
    System.SysUtils; //for TStringSplitOptions

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

  function InlineSvgStyle_OLD(const SvgText: string): string;
  begin
    var ResultSvg := SvgText;

    // Find <style> block
    var StyleStart := Pos('<style>', ResultSvg);
    var StyleEnd   := Pos('</style>', ResultSvg);

    if (StyleStart > 0) and (StyleEnd > StyleStart) then
    begin
      var StyleBlock := Copy(ResultSvg, StyleStart + Length('<style>'),
        StyleEnd - (StyleStart + Length('<style>')));

      // Split into lines/rules
      var Lines := StyleBlock.Split([#10, #13], TStringSplitOptions.ExcludeEmpty);

      for var Line in Lines do
      begin
        var TrimmedLine := Trim(Line);
        // Example: .cls-1{fill:#fff;stroke:#000;stroke-width:2;}
        if TrimmedLine.StartsWith('.') and TrimmedLine.Contains('{') then
        begin
          var ClassName := Copy(TrimmedLine, 2, Pos('{', TrimmedLine) - 2); // remove leading '.'
          var RuleBody := Copy(TrimmedLine, Pos('{', TrimmedLine) + 1,
            Pos('}', TrimmedLine) - Pos('{', TrimmedLine) - 1);

          // Split properties by ';'
          var Props := RuleBody.Split([';'], TStringSplitOptions.ExcludeEmpty);
          var InlineAttrs := '';
          for var Prop in Props do
          begin
            var Parts := Prop.Split([':'], TStringSplitOptions.ExcludeEmpty);
            if Length(Parts) = 2 then
            begin
              var Name := Trim(Parts[0]);
              var Value := Trim(Parts[1]);

              // Handle shorthand stroke (e.g. "stroke: red 2px dashed")
              if (Name = 'stroke') then
              begin
                var StrokeParts := Value.Split([' '], TStringSplitOptions.ExcludeEmpty);
                if Length(StrokeParts) > 0 then
                  InlineAttrs := InlineAttrs + ' stroke="' + StrokeParts[0] + '"';
                if Length(StrokeParts) > 1 then
                  InlineAttrs := InlineAttrs + ' stroke-width="' + StrokeParts[1] + '"';
                if Length(StrokeParts) > 2 then
                  InlineAttrs := InlineAttrs + ' stroke-dasharray="' + StrokeParts[2] + '"';
              end
              else if (Name = 'fill') or (Name = 'stroke-width') or
                      (Name = 'fill-opacity') or (Name = 'stroke-opacity') or
                      (Name = 'stroke-linecap') or (Name = 'stroke-linejoin') or
                      (Name = 'stroke-dasharray') or (Name = 'font-family') or
                      (Name = 'font-size') or (Name = 'font-weight') then
                InlineAttrs := InlineAttrs + ' ' + Name + '="' + Value + '"';
            end;
          end;

          if InlineAttrs <> '' then
          begin
            // Replace specific class attribute with respective inline attributes
            ResultSvg := StringReplace(ResultSvg,
              'class="' + ClassName + '"',
              Trim(InlineAttrs),
              [rfReplaceAll, rfIgnoreCase]);
          end;
        end;
      end;

      // Remove the <style> block entirely
      Delete(ResultSvg, StyleStart, StyleEnd + Length('</style>') - StyleStart);
    end;

    Result := ResultSvg;
  end;

  function InlineSvgStyle(const SvgText: string): string;
  begin
    var ResultSvg := SvgText;

    // Locate <style> block boundaries
    var StyleStart := Pos('<style>', ResultSvg);
    var StyleEnd := Pos('</style>', ResultSvg);

    if (StyleStart > 0) and (StyleEnd > StyleStart) then
    begin
      // Extract raw CSS style content
      var StyleBlock := Copy(ResultSvg, StyleStart + Length('<style>'),
        StyleEnd - (StyleStart + Length('<style>')));

      // Map class names to merged inline attributes
      var ClassMap := TDictionary<string, string>.Create;

      // Split style block into individual rules
      var Lines := StyleBlock.Split([#10, #13], TStringSplitOptions.ExcludeEmpty);

      for var Line in Lines do
      begin
        var TrimmedLine := Trim(Line);

        // Only process class-based rules (e.g. .cls-1{...})
        if TrimmedLine.StartsWith('.') and TrimmedLine.Contains('{') then
        begin
          // Extract selector list and rule body
          var SelectorPart := Copy(TrimmedLine, 1, Pos('{', TrimmedLine) - 1);
          var RuleBody := Copy(TrimmedLine, Pos('{', TrimmedLine) + 1,
            Pos('}', TrimmedLine) - Pos('{', TrimmedLine) - 1);

          // Support grouped selectors (e.g. .cls-1, .cls-2)
          var ClassNames := SelectorPart.Split([','], TStringSplitOptions.ExcludeEmpty);
          var Props := RuleBody.Split([';'], TStringSplitOptions.ExcludeEmpty);

          for var RawClass in ClassNames do
          begin
            var ClassName := Trim(RawClass);
            if ClassName.StartsWith('.') then Delete(ClassName, 1, 1);

            // Merge with any existing attributes for this class
            var Existing := '';
            ClassMap.TryGetValue(ClassName, Existing);

            for var Prop in Props do
            begin
              var Parts := Prop.Split([':'], TStringSplitOptions.ExcludeEmpty);
              if Length(Parts) = 2 then
              begin
                var Name := Trim(Parts[0]);
                var Value := Trim(Parts[1]);

                // Expand shorthand stroke (e.g. "stroke: red 2px dashed")
                if Name = 'stroke' then
                begin
                  var StrokeParts := Value.Split([' '], TStringSplitOptions.ExcludeEmpty);
                  if Length(StrokeParts) > 0 then Existing := Existing + ' stroke="' + StrokeParts[0] + '"';
                  if Length(StrokeParts) > 1 then Existing := Existing + ' stroke-width="' + StrokeParts[1] + '"';
                  if Length(StrokeParts) > 2 then Existing := Existing + ' stroke-dasharray="' + StrokeParts[2] + '"';
                end
                // Map supported style properties to inline attributes
                else if (Name = 'fill') or (Name = 'stroke-width') or
                        (Name = 'fill-opacity') or (Name = 'stroke-opacity') or
                        (Name = 'stroke-linecap') or (Name = 'stroke-linejoin') or
                        (Name = 'stroke-dasharray') or (Name = 'fill-rule') or
                        (Name = 'font-family') or (Name = 'font-size') or
                        (Name = 'font-weight') then
                  Existing := Existing + ' ' + Name + '="' + Value + '"';
              end;
            end;

            // Store merged inline attributes for this class
            ClassMap[ClassName] := Trim(Existing);
          end;
        end;
      end;

      // Replace each class="..." with its corresponding inline attributes
      for var Pair in ClassMap do
        ResultSvg := StringReplace(ResultSvg,
          'class="' + Pair.Key + '"',
          Pair.Value,
          [rfReplaceAll, rfIgnoreCase]);

      // Remove the original <style> block entirely
      Delete(ResultSvg, StyleStart, StyleEnd + Length('</style>') - StyleStart);
      ClassMap.Free;
    end;

    Result := ResultSvg;
  end;

end.
