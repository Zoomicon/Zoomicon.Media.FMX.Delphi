//Description: MediaPlayerEx control
//Source: https://github.com/Zoomicon/Zoomicon.Media.FMX.Delphi
//Author: George Birbilis (http://zoomicon.com)

unit Zoomicon.Media.FMX.MediaPlayerEx;

interface
  {$region 'Used units'}
  uses
    System.Classes, //for GroupDescendentsWith, RegisterComponents
    //
    FMX.Media, //for TMediaPlayer
    FMX.Types, //for TTimer, RegisterFmxClasses
    //
    Zoomicon.Media.FMX.Models; //for IMediaPlayer
  {$endregion}

  const
    TIMER_INTERVAL = 10; //ms

  type

    {$REGION 'TMediaPlayerEx'}

    TMediaPlayerEx = class(TMediaPlayer, IMediaPlayer)

    //-- Fields

    protected
      FVolumeBeforeMuting: Single; //0-1
      FMuted: Boolean;
      FAutoPlaying: Boolean;
      FLooping: Boolean;
      FTimer: TTimer;
      FLastTime: TMediaTime;
      FFileNameNotTemp: Boolean;
      {Events}
      FOnPlay: TOnPlay;
      FOnPause: TOnPause;
      FOnStop: TOnStop;
      FOnAtStart: TOnAtStart;
      FOnAtEnd: TOnAtEnd;
      FOnCurrentTimeChange: TCurrentTimeChange;

    //-- Methods

    protected
      procedure HandleTimer(Sender: TObject); virtual;
      procedure DoAtStart; virtual;
      procedure DoAtEnd; virtual;
      {TimerStarted}
      function IsTimerStarted: Boolean; virtual;
      procedure SetTimerStarted(const Value: Boolean); virtual;
      {MediaLoaded}
      function IsMediaLoaded: Boolean;
      {Playing}
      function IsPlaying: Boolean; virtual;
      procedure SetPlaying(const Value: Boolean); virtual;
      {AtStart}
      function IsAtStart: Boolean; virtual;
      {AtEnd}
      function IsAtEnd: Boolean; virtual;
      {Finished}
      function IsFinished: Boolean; virtual;
      {Muted}
      function IsMuted: Boolean; virtual;
      procedure SetMuted(const Value: Boolean); virtual;
      {AutoPlaying}
      function IsAutoPlaying: Boolean; virtual;
      procedure SetAutoPlaying(const Value: Boolean); virtual;
      {Looping}
      function IsLooping: Boolean; virtual;
      procedure SetLooping(const Value: Boolean); virtual;
      {FileName}
      function GetFileName: String; //Note: there's no TMediaPlayer.GetFileName (the ancestor FileName property reads FFileName private field)
      procedure SetFileName(const Value: string); //Note: TMediaPlayer.SetFileName is private (can set the ancestor FileName property)
      procedure ChangeFileName(const Value: string); virtual;
      {Stream}
      procedure SetStream(const Value: TStream);

    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure Play(const FromStart: Boolean = false); virtual;
      procedure Rewind; virtual;
      procedure Pause; virtual;
      procedure Stop; virtual;
      procedure Clear; virtual;

    //-- Properties

    protected
      property TimerStarted: Boolean read IsTimerStarted write SetTimerStarted;

    published
      property MediaLoaded: Boolean read IsMediaLoaded;
      property Playing: Boolean read IsPlaying write SetPlaying stored false;
      property AtStart: Boolean read IsAtStart;
      property AtEnd: Boolean read IsAtEnd;
      property Finished: Boolean read IsFinished;
      property Muted: Boolean read IsMuted write SetMuted;
      property AutoPlaying: Boolean read IsAutoPlaying write SetAutoPlaying;
      property Looping: Boolean read IsLooping write SetLooping;
      property FileName: string read GetFileName write SetFileName stored FFileNameNotTemp;
      property Stream: TStream write SetStream stored false;
      {Events}
      property OnPlay: TOnPlay read FOnPlay write FOnPlay;
      property OnPause: TOnPause read FOnPause write FOnPause;
      property OnStop: TOnStop read FOnStop write FOnStop;
      property OnAtStart: TOnAtStart read FOnAtStart write FOnAtStart;
      property OnAtEnd: TOnAtEnd read FOnAtEnd write FOnAtEnd;
      property OnCurrentTimeChange: TCurrentTimeChange read FOnCurrentTimeChange write FOnCurrentTimeChange;
    end;

    {$ENDREGION}

  {$REGION 'Helpers'}

  procedure SkipID3header(const Stream: TStream);
  function FindAudioExt(const AStream: TStream): string;
  function SafeDelete(const Path: string): Boolean; //TODO: move to Zoomicon.Helpers.RTL? (maybe to a TFileHelper)

  procedure Register;

implementation
  uses
    System.IOUtils, //for TPath.GetTempFileName
    System.Math, //for Min
    System.SysUtils; //for fmOpenWrite

  {$REGION 'TMediaPlayerEx'}

  {$region 'Initialization / Destruction'}

  constructor TMediaPlayerEx.Create(AOwner: TComponent);
  begin
    inherited;

    FFileNameNotTemp := false;

    FTimer := TTimer.Create(self); //ticker/metronome to compare FLastTime to CurrentTime and send OnCurrentTimeChangeEvent
    with FTimer do
    begin
      Interval := TIMER_INTERVAL;
      OnTimer := HandleTimer;
    end;
  end;

  destructor TMediaPlayerEx.Destroy;
  begin
    Stream := nil; //must do (calls SetStream) to free any temporary file we had created //do not free FStream, we hadn't created it
    inherited; //do last
  end;

  {$endregion}

  {$region 'Media Control'}

  procedure TMediaPlayerEx.Play(const FromStart: Boolean = false);
  begin
    if FromStart then
      Rewind;

    if (not IsPlaying) then
    begin
      TimerStarted := true; //start timer (ticker/metronome) used to detect and send OnCurrentTimeChange event
      inherited Play;
      if Assigned(FOnPlay) then
        FOnPlay;
    end;
  end;

  procedure TMediaPlayerEx.Rewind;
  begin
    CurrentTime := 0; //if (FLastTime <> 0) this will send an OnCurrentTimeChange event

    if (not TimerStarted) then //if not playing (timer that monitors time change only runs then) send an OnAtStart event
      DoAtStart;
  end;

  procedure TMediaPlayerEx.Pause;
  begin
    if (not IsPlaying) then
      exit;

    inherited Stop; //this Pauses
    TimerStarted := false; //stop timer used to detect and send OnCurrentTimeChange event (to conserve resources)

    if Assigned(FOnPause) then
      FOnPause;
  end;

  procedure TMediaPlayerEx.Stop;
  begin
    Pause; //this will also call StopTimer;
    Rewind;
    if Assigned(FOnStop) then
      FOnStop;
  end;

  {$endregion}

  {$region 'Timer'}

  procedure TMediaPlayerEx.HandleTimer;
  begin
    if FAutoPlaying and MediaLoaded and (not IsPlaying) then //since TimerStarted=true we're either playing or waiting for media to load to autoplay it
      Play; //does nothing if Playing, but checking it anyway above to avoid method call cost since this is called often (note this will though result in twice checking IsPlaying when it is true since Play also checks it)

    var newTime := CurrentTime; //keep locally since it changes
    if (FLastTime <> newTime) then
    begin
      FLastTime := newTime;
      if Assigned(OnCurrentTimeChange) then
        OnCurrentTimeChange(Self, newTime);

      if IsAtStart then
        DoAtStart;
      if IsAtEnd then //if media has Duration=0 (though for CurrentTime to have changed, other media would have to be loaded before) we'll fire OnAtStart and then OnAtEnd
        DoAtEnd;
    end;
  end;

  function TMediaPlayerEx.IsTimerStarted: Boolean;
  begin
    result := FTimer.Enabled;
  end;

  procedure TMediaPlayerEx.SetTimerStarted(const Value: Boolean);
  begin
    //Start timer
    if Value and (not IsTimerStarted) then
    begin
      FLastTime := CurrentTime; //keep CurrentTime before starting the timer (do it before it gets started, since OnTimer event handler also updates FLastTime)
      FTimer.Enabled := true; //we know (Value = true)
    end

    //Stop timer
    else if (not Value) and IsTimerStarted then
    begin
      FTimer.Enabled := false; //we know (Value = false)
      FLastTime := CurrentTime; //keep CurrentTime after stopping the timer (do it after it gets stopped, since OnTimer event handler also updates FLastTime)
    end;
  end;

  {$endregion}

  {$region 'MediaLoaded'}

  function TMediaPlayerEx.IsMediaLoaded: Boolean;
  begin
    result := (State <> TMediaState.Unavailable);
  end;

  {$endregion}

  {$region 'Playing'}

  function TMediaPlayerEx.IsPlaying: Boolean;
  begin
    result := (State = TMediaState.Playing);
  end;

  procedure TMediaPlayerEx.SetPlaying(const Value: Boolean);
  begin
    if Value then
      Play
    else
      Pause;
  end;

  {$endregion}

  {$region 'AtStart'}

  function TMediaPlayerEx.IsAtStart: Boolean;
  begin
    result := (CurrentTime = 0);
  end;

  procedure TMediaPlayerEx.DoAtStart;
  begin
    if Assigned(FOnAtStart) then
      FOnAtStart;
  end;

  {$endregion}

  {$region 'AtEnd'}

  function TMediaPlayerEx.IsAtEnd: Boolean;
  begin
    result := (CurrentTime = Duration);
  end;

  procedure TMediaPlayerEx.DoAtEnd;
  begin
    if Assigned(FOnAtEnd) then
      FOnAtEnd;
    if FLooping then
      CurrentTime := 0; //TODO: depending on Timer resolution this may fail to fire OnAtStart (but if we call DoAtStart it may fire twice)
  end;

  {$endregion}

  {$region 'Finished'}

  function TMediaPlayerEx.IsFinished: Boolean;
  begin
    result := (not Playing) and AtEnd;
  end;

  {$endregion}

  {$region 'Muted'}

  function TMediaPlayerEx.IsMuted: Boolean;
  begin
    result := FMuted;
  end;

  procedure TMediaPlayerEx.SetMuted(const Value: Boolean);
  begin
    //Mute
    if Value and (not FMuted) then
      begin
        FVolumeBeforeMuting := Volume;
        Volume := 0;
        FMuted := Value;
      end

    //Unmute
    else if (not Value) and FMuted then
      begin
      Volume := FVolumeBeforeMuting;
      FMuted := Value;
      end;
  end;

  {$endregion}

  {$region 'AutoPlaying'}

  function TMediaPlayerEx.IsAutoPlaying: Boolean; //IMediaPlayer implementation
  begin
    result := FAutoPlaying;
  end;

  procedure TMediaPlayerEx.SetAutoPlaying(const Value: Boolean);
  begin
    FAutoPlaying := Value;
    if Value and MediaLoaded then
      Play;
  end;

  {$endregion}

  {$region 'Looping'}

  function TMediaPlayerEx.IsLooping: Boolean; //IMediaPlayer implementation
  begin
    result := FLooping;
  end;

  procedure TMediaPlayerEx.SetLooping(const Value: Boolean);
  begin
    FLooping := Value;
  end;

  {$endregion}

  {$region 'Content'}

  procedure TMediaPlayerEx.Clear;
  begin
    Stop; //this does TimerStarted := false

    //clear temp file (backing assigned stream), if any
    if (not FFileNameNotTemp) and (FileName <> '') then //if we were using a Stream (saved to temp) instead of external FileName
      SafeDelete(FileName); //delete temp file we had allocated for Stream //Note: must do this after stop and clear (FileName:='' does that above)

    inherited Clear; //this does FreeAndNil(Media) and (at the ancestor level) also FileName:=''

    FFileNameNotTemp := true; //Note: SetFileName assumes this has been set here
  end;

  {$region 'FileName'}

  function TMediaPlayerEx.GetFileName: String;
  begin
    result := inherited FileName;
  end;

  procedure TMediaPlayerEx.SetFileName(const Value: string);
  begin
    Clear; //calling to delete any temp file (used by SetStream) //will set FFileNameNotTemp := true
    ChangeFileName(Value);
 end;

  procedure TMediaPlayerEx.ChangeFileName(const Value: string);
  begin
    if (Value.IsEmpty) then
      Clear //this also calls Stop (which will also stop Timer that tracks time change) in our implementation (and via "inherited Clear" does FreeAndNil(Media) and [at the ancestor level] FileName:='')
    else
    begin
      if FAutoPlaying then
        TimerStarted := true; //HandleTimer also checks if media is loaded and if autoplaying will start playback
      inherited FileName := Value;
    end;
  end;

  {$endregion}

  {$region 'Stream'}

  procedure TMediaPlayerEx.SetStream(const Value: TStream);
  begin
    //first stop player and release file it may be holding locked
    ChangeFileName(''); //this will call Clear (this also calls Stop in our implementation (and via "inherited Clear" does FreeAndNil(Media) and [at the ancestor level] FileName:='')) //don't use SetFileName, it will reset FFileNameNotTemp

    //--- Set new content

    if Assigned(Value) then
    begin
      var FTempFileName := TPath.GetTempFileName + FindAudioExt(Value); //don't use TPath.ChangeExtension - temp file name is of form tmp.XX on OS-X so we'd end up with lots of same named temp files (like tmp.mp3)
      var F := TFileStream.Create(FTempFileName, fmCreate or fmOpenWrite {or fmShareDenyNone}); //fmShareDenyNote not needed since we'll close the temp file after writing to it, then pass the filename to the ancestorTMediaPlayer
      try
        try
          var LastPos := Value.Position;
          F.CopyFrom(Value);
          Value.Position := LastPos;
          FFileNameNotTemp := false; //note we're using a temp filename
          //Log.d('Info', Self, 'Copied audio to temp file: ' + FTempFileName);
        except //issue during Copy
          Log.d('Error', Self, 'Failed to copy audio to temp file: ' + FTempFileName);
          SafeDelete(FTempFileName); //cleanup temp file if copy fails
          raise; //re-raise exception to caller
        end;
      finally
        FreeAndNil(F);
      end;

      //tell TMediaPlayer ancestor to open the new TempFileName
      ChangeFileName(FTempFileName); //don't use SetFileName, it will clear FStream
    end;
  end;

  {$endregion}

  {$endregion}

  {$ENDREGION}

  {$REGION 'Helpers'}

  procedure SkipID3header(const Stream: TStream);
  var
    SavedPos: Int64;
    hdr: array[0..9] of Byte;
    remaining: Int64;
    id3Size: Int64;
    totalSkip: Int64;
    flags: Byte;
  begin
    if not Assigned(Stream) then
      Exit;

    SavedPos := Stream.Position;
    remaining := Stream.Size - SavedPos;

    // Need at least 10 bytes for an ID3v2 header
    if remaining < 10 then
      Exit;

    // Read 10 bytes defensively
    FillChar(hdr, SizeOf(hdr), 0);
    try
      Stream.ReadBuffer(hdr, 10);
    except
      // Any read error: restore position and bail out
      Stream.Position := SavedPos;
      Exit;
    end;

    // Check for "ID3" signature
    if (hdr[0] = Ord('I')) and (hdr[1] = Ord('D')) and (hdr[2] = Ord('3')) then
    begin
      // flags byte at offset 5
      flags := hdr[5];

      // size is a synchsafe 28-bit integer in bytes 6..9
      id3Size := ((hdr[6] and $7F) shl 21) or
                 ((hdr[7] and $7F) shl 14) or
                 ((hdr[8] and $7F) shl 7)  or
                 (hdr[9] and $7F);

      // total tag length = 10 (header) + size
      totalSkip := 10 + id3Size;

      // If footer present (ID3v2.4 footer flag bit 4 / 0x10) add 10 bytes
      if (flags and $10) <> 0 then
        Inc(totalSkip, 10);

      // Clamp so we never move past the stream end
      if totalSkip > remaining then
        totalSkip := remaining;

      // Advance position past the whole ID3v2 tag
      Stream.Position := SavedPos + totalSkip;
    end
    else
    begin
      // Not an ID3v2 tag — restore original position
      Stream.Position := SavedPos;
    end;
  end;

  function FindAudioExt(const AStream: TStream): string;
    type
      THeader = record
        Signature: TArray<Byte>; // dynamic array of bytes
        Offset: Integer; // where in the stream the signature starts
        Ext: string; // detected file extension
      end;

    const
      Headers: array[0..8] of THeader = (
        // MP3 — frame sync FF FB or FF F3 or FF F2
        (Signature: [$FF,$FB]; Offset: 0; Ext: '.mp3'),
        (Signature: [$FF,$F3]; Offset: 0; Ext: '.mp3'),
        (Signature: [$FF,$F2]; Offset: 0; Ext: '.mp3'),

        // WAV — "RIFF"
        (Signature: [$52,$49,$46,$46]; Offset: 0; Ext: '.wav'),

        // OGG — "OggS"
        (Signature: [$4F,$67,$67,$53]; Offset: 0; Ext: '.ogg'),

        // M4A / AAC — 'ftyp' at offset 4
        (Signature: [$66,$74,$79,$70]; Offset: 4; Ext: '.m4a'),

        // AIFF — "FORM"
        (Signature: [$46,$4F,$52,$4D]; Offset: 0; Ext: '.aiff'),

        // FLAC — "fLaC"
        (Signature: [$66,$4C,$61,$43]; Offset: 0; Ext: '.flac'),

        // WMA / ASF — ASF header
        (Signature: [$30,$26,$B2,$75]; Offset: 0; Ext: '.wma')
      );

    var
      Buf: array[0..15] of Byte;
      i, j: Integer;
      SavedPos: Int64;
      Header: THeader;
      SigLen: Integer;
  begin
    Result := '.bin';

    if not Assigned(AStream) then Exit;

    if AStream.Size < 2 then Exit;

    SavedPos := AStream.Position; //remember original position

    SkipID3header(AStream); //some file formats may contain an ID3v2 header (metadata), skip that

    FillChar(Buf, SizeOf(Buf), 0);
    AStream.ReadBuffer(Buf, Min(AStream.Size, 16));

    for i := Low(Headers) to High(Headers) do
    begin
      Header := Headers[i];
      SigLen := Length(Header.Signature);

      // skip if stream too short for this header
      if (AStream.Size < Header.Offset + SigLen) then
        Continue;

      // compare bytes
      for j := 0 to SigLen - 1 do
        if Buf[Header.Offset + j] <> Header.Signature[j] then
          Break
        else if j = SigLen - 1 then
        begin
          Result := Header.Ext;
          AStream.Position := SavedPos;
          Exit;
        end;

    end;

    AStream.Position := SavedPos;
  end;

  function SafeDelete(const Path: String): Boolean;
  begin
    try
      TFile.Delete(Path); //not using System.SysUtils.DeleteFile (which doesn't throw exceptions), requires adding platform-specific units (e.g. for MacOS-X) to uses clause to remove non-inlining method warnings
      result := True;
      //Log.d('Info', nil, 'Deleted temp audio file: ' + Path);
    except //ignore any exception during deletion and just log it
      on E: Exception do
      begin
        Log.d('Error', E, 'Could not delete temp audio file: ' + Path);
        result := False;
      end;
    end;
  end;

  {$ENDREGION}

  {$REGION 'Registration'}

  procedure RegisterSerializationClasses;
  begin
    RegisterFmxClasses([TMediaPlayerEx]);
  end;

  procedure Register;
  begin
    GroupDescendentsWith(TMediaPlayerEx, TComponent);
    RegisterSerializationClasses;
    RegisterComponents('Zoomicon', [TMediaPlayerEx]);
  end;

  {$ENDREGION}

initialization
  RegisterSerializationClasses; //don't call Register here, it's called by the IDE automatically on a package installation (fails at runtime)

end.

