Attribute VB_Name = "Module2"


Public mBoincTotalHostAvg As Long

   

Option Explicit



    Public Function LogBoincCredits()


On Error GoTo ErrTrap


      Dim sXMLFile As String
      sXMLFile = BoincDataDir + "client_state.xml"
        
        
      Dim fI As Integer
      fI = FreeFile
      
      Open sXMLFile For Input As #fI
      
        Dim sTemp As String
        Dim sProject As String
        Dim dCredit As Double
        Dim totalCredit As Double
        Dim dTotalProjects As Double
        Dim dTotalHostAvg As Double
            Dim sProjects As String
            
            Dim dLockTime As Date
            Dim dAvgLockAge As Double
            Dim dAvgLockCount As Double
            
            Dim bValidLockTime As Boolean
            Dim sHostId As String
            Dim dAvgCredit As Double
            Dim sSmallProj As String
            Dim sSmallProjExpanded As String
            Dim sProjectsExpanded As String
            Do While EOF(fI) = False
            
            Line Input #fI, sTemp
            
                If InStr(1, sTemp, "<project_name>") > 0 Then
                    sProject = XMLValue(sTemp)
                    sSmallProj = Left(sProject, 5)
                    sHostId = ""
                    dCredit = 0
                    dAvgCredit = 0
                    dLockTime = CDate("1-1-1900")
                    bValidLockTime = False
                    If InStr(1, sProjects, sSmallProj) = 0 Then
                        sProjects = sProjects + sSmallProj + ":"
                    End If
                End If
                If InStr(1, sTemp, "host_total_credit") > 0 Then
                    dCredit = Val(XMLValue(sTemp))
                    dTotalProjects = dTotalProjects + 1
                    totalCredit = totalCredit + dCredit
                    Call AddCredits(sProject, dCredit, 0, "host_total_credit")
                End If
                If InStr(1, sTemp, "hostid") > 0 Then
                    sHostId = XMLValue(sTemp)
                End If
                If InStr(1, sTemp, "host_expavg_credit") > 0 Then
                    dAvgCredit = Val(XMLValue(sTemp))
                    sSmallProjExpanded = sSmallProj + "_" + Trim(Math.Round(Val(dAvgCredit), 0)) + "_" + Trim(sHostId)
                    dLockTime = HarvestLockTime(fI, bValidLockTime)
                    If InStr(1, sProjectsExpanded, sSmallProjExpanded) = 0 And bValidLockTime Then
                        sProjectsExpanded = sProjectsExpanded + sSmallProjExpanded + ":"
                    End If
                    If bValidLockTime And dAvgCredit > 0 Then
                       dAvgLockAge = DateDiff("s", Now, dLockTime)
                       dAvgLockCount = dAvgLockCount + 1
                        dTotalHostAvg = dTotalHostAvg + dAvgCredit
                        Call AddCredits(sProject, dAvgCredit, 0, "host_expavg_credit")
                    End If
                End If
            Loop
            Close #fI
            
        If dAvgLockCount > 0 Then
            dAvgLockAge = dAvgLockAge / dAvgLockCount
        End If
        mdBoincLockAvg = dAvgLockAge
        
        
            If Len(sProjects) > 1 Then sProjects = Left(sProjects, Len(sProjects) - 1)
            If Len(sProjectsExpanded) > 1 Then sProjectsExpanded = Left(sProjectsExpanded, Len(sProjectsExpanded) - 1)

            msBoincProjectData = sProjectsExpanded
            Call AddCredits("TOTAL", totalCredit, dTotalProjects, "TOTAL")
            Call AddCredits("AVG", dTotalHostAvg, dTotalProjects, "AVG")
             Call BoincHomogenized
          mBoincTotalHostAvg = dTotalHostAvg
          Exit Function
          
ErrTrap:
          
    End Function
    
    Public Function UnixTimeStamp() As Double
        Dim dUnix As Double
        dUnix = DateDiff("s", CDate("1-1-1970"), Now)
        UnixTimeStamp = dUnix
        
    End Function
    Public Function UnixTimeStampToDateTime(dTimeStamp As Double) As Date
    
On Error GoTo ErrTrap

        Dim dateTime As Date
        dateTime = CDate("1-1-1970")
        dateTime = DateAdd("s", dTimeStamp, dateTime)
        
        
       UnixTimeStampToDateTime = dateTime
Exit Function


ErrTrap:
UnixTimeStampToDateTime = CDate("1-1-1900")

    End Function
    Public Function HarvestLockTime(iFile As Integer, ByRef bLockTimeValid As Boolean) As Date
    
        'Verify Lock time is valid with Boinc:
        On Error GoTo ErrTrap
        
        Dim sTemp As String
            Dim dunixtime As Double
            Dim hiunixtime As Double

        bLockTimeValid = False
        While Not EOF(iFile)
        
        Line Input #iFile, sTemp
        
                If InStr(1, sTemp, "</project>") > 0 Then
                    Dim locktime As Date
                    locktime = UnixTimeStampToDateTime(hiunixtime)
                    If DateDiff("d", locktime, Now) < 3 Then bLockTimeValid = True 'LockTime must be within 3 days to be valid, otherwise user will need to update their project!
                   HarvestLockTime = locktime
                   Exit Function
                End If

                If InStr(1, sTemp, "rec_time") > 0 Then
                    dunixtime = Val(XMLValue(sTemp))
                    If dunixtime > hiunixtime Then hiunixtime = dunixtime
                End If
                If InStr(1, sTemp, "min_rpc_time") > 0 Then
                    dunixtime = Val(XMLValue(sTemp))
                    If dunixtime > hiunixtime Then hiunixtime = dunixtime
                End If


           Wend
            HarvestLockTime = UnixTimeStampToDateTime(hiunixtime): Exit Function
            
ErrTrap:
    HarvestLockTime = CDate("1-1-1900")
        
    End Function
    Public Function ReturnBoincCreditsAtPointInTime(ByVal lLookbackSecs) As Double
       On Error GoTo ErrTrap
       
            Dim dtEnd As Date
            dtEnd = Now
            Dim dtStart As Date
            dtStart = DateAdd("s", -lLookbackSecs, dtEnd)
            Dim sPath As String
            sPath = linux.BoincDataDir
            sPath = sPath + "gridcoin.dat"
            
            Dim iFF As Integer
            iFF = FreeFile
            Open sPath For Input As #iFF
            Dim sTemp As String
            Dim dTotalCreditsStart As Double
            Dim dTotalAvgStart As Double
            Dim dProjects As Double
            Dim dtEntry As Date
            Dim iRows As Long
            
            Do While Not EOF(iFF)
                Line Input #iFF, sTemp
                
                sTemp = FromBase64(sTemp)
                Dim vTemp() As String
                vTemp = Split(sTemp, ",")
                iRows = iRows + 1
                
                If UBound(vTemp) > 3 Then
                    If vTemp(1) = "TOTAL" Then
                        dtEntry = vTemp(0)
                        If dtEntry > dtStart And dTotalCreditsStart = 0 Then
                            dTotalCreditsStart = vTemp(2)
                            dProjects = vTemp(3)
                        End If
                    End If

                    If vTemp(1) = "AVG" Then
                        dtEntry = vTemp(0)
                        If dtEntry > dtStart And dTotalAvgStart = 0 Then
                            dTotalAvgStart = vTemp(2)
                            
                            
                        End If
                    End If
                    
                    If dtEntry > dtStart And dTotalAvgStart > 0 And dTotalCreditsStart > 0 Then Exit Do
                    
                End If
                DoEvents
                
            Loop
            Close #iFF
            
            mdBoincProjects = dProjects
            If mdBoincProjects < 0 Then mdBoincProjects = 0
            mdBoincCreditsAvgAtPointInTime = dTotalAvgStart
            mdBoincCreditsAtPointInTime = dTotalCreditsStart
            
            ReturnBoincCreditsAtPointInTime = dTotalAvgStart
           
           Exit Function
ErrTrap:

           
    End Function

Public Function StrToByte(sData As String) As Byte()

  Dim b() As Byte
  
  b = StrConv(sData, vbFromUnicode)
  StrToByte = b
End Function
Public Function ByteToString(b() As Byte) As String
Dim sOut As String
sOut = Trim(b)
ByteToString = sOut
End Function
Public Function ToBase64(sData As String) As String
ToBase64 = Base64Encode(sData)
End Function

Public Function FromBase64(sData As String) As String
FromBase64 = Base64Decode(sData)
End Function

      
 
Public Function BoincComponentA() As Double
'AvgLockTime is stored in seconds
If mdBoincLockAvg < (10 * 3600#) Then BoincComponentA = 100
If mdBoincLockAvg > (7 * 3600#) Then BoincComponentA = 80
If mdBoincLockAvg < 0 Or mdBoincLockAvg > (10 * 3600#) Then BoincComponentA = 0
mdBoincComponentA = BoincComponentA
End Function


Public Function BoincComponentB() As Double
Dim dCredits As Double
    ReturnBoincCreditsAtPointInTime (1)
    dCredits = mclsUtilization.BoincCreditsAvgAtPointInTime
Dim dOut As Double
dOut = dCredits / 10
If dOut > 100 Then dOut = 100
If dOut < 0 Then dOut = 0
BoincComponentB = dOut
linux.mlBoincThreads = mclsUtilization.BoincProjects
mdBoincComponentB = BoincComponentB
linux.mdBoincAvgCredits = dCredits

End Function


Public Function BoincHomogenized() As Double
DoEvents

    Dim dOut As Double
    dOut = (BoincComponentA + BoincComponentB) / 2
    BoincHomogenized = dOut
  linux.mlBoincUtilization = dOut
    
End Function















Private Function AddCredits(ByVal sName As String, ByVal dCredit As Double, ByVal dProjectCount As Double, ByVal sCounterType As String)
        
    Dim oFF As Integer
    On Error GoTo ErrTrap
    oFF = FreeFile
    
            Dim sPath As String
            sPath = linux.BoincDataDir + "gridcoin.dat"
            
            
            
            Open sPath For Append As #oFF
            
            Dim sRow As String
            sRow = Trim(Now) + "," + sName + "," + Trim(dCredit) + "," + Trim(dProjectCount) + "," + sCounterType
            sRow = ToBase64(sRow)
          Print #oFF, sRow
            Close #oFF
        

ErrTrap:
Close #oFF

    End Function
    



Private Function XMLValue(ByVal sRow As String) As String
    On Error GoTo ErrTrap
    
            Dim iEnd As Long
            Dim iStart As Long
            iStart = InStr(1, sRow, Chr(62))
            If iStart = 0 Then Exit Function
            iEnd = InStr(iStart, sRow, Chr(60) + Chr(47))
            
            If iEnd = 0 Then Exit Function
            Dim sValue As String

            sValue = Mid(sRow, iStart + 1, iEnd - iStart - 1)
            XMLValue = sValue
ErrTrap:
    End Function
    
    
    
