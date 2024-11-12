Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Net.Http

# Prompt the user to enter the URL
$form = New-Object System.Windows.Forms.Form
$form.Text = "输入URL"
$form.Width = 400
$form.Height = 150

$label = New-Object System.Windows.Forms.Label
$label.Text = "请输入网易云音乐的歌曲链接："
$label.AutoSize = $true
$label.Top = 20
$label.Left = 10
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Width = 350
$textBox.Top = 50
$textBox.Left = 10
$form.Controls.Add($textBox)

$buttonOk = New-Object System.Windows.Forms.Button
$buttonOk.Text = "确定"
$buttonOk.Top = 80
$buttonOk.Left = 150
$buttonOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $buttonOk
$form.Controls.Add($buttonOk)

if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $url = $textBox.Text

    # Extract the song ID from the URL
    if ($url -match "id=(\d+)") {
        $songId = $matches[1]
        # Construct the new URL
        $newUrl = "http://music.163.com/song/media/outer/url?id=$songId.mp3"
        [System.Windows.Forms.MessageBox]::Show("得到的音频链接：" + $newUrl, "生成的链接")

        # Create a SaveFileDialog to prompt the user for the save location
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = "MP3 files (*.mp3)|*.mp3"
        $saveFileDialog.Title = "保存音频文件"
        $saveFileDialog.ShowDialog() | Out-Null
        $saveLocation = $saveFileDialog.FileName

        if ($saveLocation) {
            # Extract the file name from the save location
            $fileName = [System.IO.Path]::GetFileName($saveLocation)

            # Use HttpClient to download the audio file with progress reporting
            $httpClient = New-Object System.Net.Http.HttpClient
            $response = $httpClient.GetAsync($newUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            $stream = $response.Content.ReadAsStreamAsync().Result
            $totalBytes = $response.Content.Headers.ContentLength

            # Create a progress bar form
            $progressForm = New-Object System.Windows.Forms.Form
            $progressForm.Text = "下载进度"
            $progressForm.Width = 400
            $progressForm.Height = 150

            $progressBar = New-Object System.Windows.Forms.ProgressBar
            $progressBar.Minimum = 0
            $progressBar.Maximum = 100
            $progressBar.Width = 350
            $progressBar.Height = 30
            $progressBar.Top = 50
            $progressBar.Left = 10
            $progressForm.Controls.Add($progressBar)

            $fileNameLabel = New-Object System.Windows.Forms.Label
            $fileNameLabel.Text = "正在下载：" + $fileName
            $fileNameLabel.AutoSize = $true
            $fileNameLabel.Top = 20
            $fileNameLabel.Left = 10
            $progressForm.Controls.Add($fileNameLabel)

            $progressForm.Show()

            $fileStream = [System.IO.File]::Create($saveLocation)
            $buffer = New-Object byte[] 8192
            $totalRead = 0
            $read = 0

            while (($read = $stream.ReadAsync($buffer, 0, $buffer.Length).Result) -gt 0) {
                $fileStream.WriteAsync($buffer, 0, $read).Wait()
                $totalRead += $read
                $progress = [math]::Round(($totalRead / $totalBytes) * 100)
                $progressBar.Value = $progress
            }

            $fileStream.Close()
            $stream.Close()
            $progressForm.Close()

            # Check if the file is a valid MP3
            if (Test-Path $saveLocation) {
                $fileInfo = Get-Item $saveLocation
                if ($fileInfo.Length -gt 0) {
                    [System.Windows.Forms.MessageBox]::Show("音频文件已下载到：" + $saveLocation, "下载完成")
                } else {
                    [System.Windows.Forms.MessageBox]::Show("下载的文件无效，请重试。", "下载失败")
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("文件未能成功下载，请重试。", "下载失败")
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("未选择保存位置。", "操作取消")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("无法从输入的URL中提取歌曲ID。请检查输入的URL格式。", "错误")
    }
}
