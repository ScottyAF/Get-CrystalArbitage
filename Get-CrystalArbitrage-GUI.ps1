#Requires -Version 7.0
<#
.SYNOPSIS
    FFXIV Crystal Datacenter Cross-World Arbitrage Scanner — WPF GUI
.NOTES
    Requires PowerShell 7+ and Windows (WPF/.NET).
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ===========================================================================
# XAML — UI Definition
# ===========================================================================
[xml]$XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="FFXIV Crystal Arbitrage Scanner"
    Height="820" Width="1380" MinHeight="600" MinWidth="900"
    Background="#1a1a2e" FontFamily="Segoe UI" FontSize="13"
    WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <!-- Colours -->
        <SolidColorBrush x:Key="BgDark"     Color="#1a1a2e"/>
        <SolidColorBrush x:Key="BgPanel"    Color="#16213e"/>
        <SolidColorBrush x:Key="BgCard"     Color="#0f3460"/>
        <SolidColorBrush x:Key="AccentBlue" Color="#00b4d8"/>
        <SolidColorBrush x:Key="AccentGold" Color="#e9c46a"/>
        <SolidColorBrush x:Key="TextLight"  Color="#e0e0e0"/>
        <SolidColorBrush x:Key="TextDim"    Color="#888888"/>
        <SolidColorBrush x:Key="Green"      Color="#2dc653"/>
        <SolidColorBrush x:Key="Yellow"     Color="#f4a261"/>
        <SolidColorBrush x:Key="Red"        Color="#e63946"/>

        <!-- Label style -->
        <Style x:Key="FieldLabel" TargetType="TextBlock">
            <Setter Property="Foreground"   Value="#888888"/>
            <Setter Property="FontSize"     Value="11"/>
            <Setter Property="Margin"       Value="0,8,0,2"/>
        </Style>

        <!-- TextBox style -->
        <Style x:Key="FieldBox" TargetType="TextBox">
            <Setter Property="Background"   Value="#0f3460"/>
            <Setter Property="Foreground"   Value="#e0e0e0"/>
            <Setter Property="BorderBrush"  Value="#00b4d8"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding"      Value="6,4"/>
            <Setter Property="CaretBrush"   Value="#e0e0e0"/>
        </Style>

        <!-- ComboBox style — full template required to override WPF defaults -->
        <Style x:Key="FieldCombo" TargetType="ComboBox">
            <Setter Property="Background"             Value="#0f3460"/>
            <Setter Property="Foreground"             Value="#e0e0e0"/>
            <Setter Property="BorderBrush"            Value="#00b4d8"/>
            <Setter Property="BorderThickness"        Value="1"/>
            <Setter Property="Padding"                Value="6,4"/>
            <Setter Property="ItemContainerStyle">
                <Setter.Value>
                    <Style TargetType="ComboBoxItem">
                        <Setter Property="Background"  Value="#0f3460"/>
                        <Setter Property="Foreground"  Value="#e0e0e0"/>
                        <Setter Property="Padding"     Value="8,5"/>
                        <Style.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter Property="Background" Value="#00b4d8"/>
                                <Setter Property="Foreground" Value="#1a1a2e"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#1a4a7a"/>
                                <Setter Property="Foreground" Value="#e0e0e0"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Setter.Value>
            </Setter>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                IsChecked="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}, Mode=TwoWay}"
                                Focusable="False" ClickMode="Press">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border Background="{TemplateBinding Background}"
                                                BorderBrush="{TemplateBinding BorderBrush}"
                                                BorderThickness="{TemplateBinding BorderThickness}"
                                                CornerRadius="2">
                                            <Grid>
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="20"/>
                                                </Grid.ColumnDefinitions>
                                                <!-- arrow -->
                                                <Path Grid.Column="1"
                                                      Data="M0,0 L4,4 L8,0 Z"
                                                      Fill="#00b4d8"
                                                      HorizontalAlignment="Center"
                                                      VerticalAlignment="Center"/>
                                            </Grid>
                                        </Border>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <!-- Selected item text -->
                            <ContentPresenter
                                Content="{TemplateBinding SelectionBoxItem}"
                                ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                Margin="8,4,24,4"
                                VerticalAlignment="Center"
                                IsHitTestVisible="False"
                                TextBlock.Foreground="#e0e0e0"/>
                            <!-- Dropdown popup -->
                            <Popup
                                IsOpen="{TemplateBinding IsDropDownOpen}"
                                Placement="Bottom"
                                AllowsTransparency="True"
                                Focusable="False"
                                PopupAnimation="Slide">
                                <Border
                                    Background="#0f3460"
                                    BorderBrush="#00b4d8"
                                    BorderThickness="1"
                                    MinWidth="{TemplateBinding ActualWidth}"
                                    MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <ScrollViewer>
                                        <ItemsPresenter/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Primary button -->
        <Style x:Key="BtnPrimary" TargetType="Button">
            <Setter Property="Background"       Value="#00b4d8"/>
            <Setter Property="Foreground"       Value="#1a1a2e"/>
            <Setter Property="FontWeight"       Value="Bold"/>
            <Setter Property="FontSize"         Value="14"/>
            <Setter Property="Padding"          Value="16,8"/>
            <Setter Property="BorderThickness"  Value="0"/>
            <Setter Property="Cursor"           Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#0096c7"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#2a4a5a"/>
                                <Setter Property="Foreground" Value="#666666"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary button -->
        <Style x:Key="BtnSecondary" TargetType="Button">
            <Setter Property="Background"       Value="#0f3460"/>
            <Setter Property="Foreground"       Value="#00b4d8"/>
            <Setter Property="FontSize"         Value="12"/>
            <Setter Property="Padding"          Value="10,6"/>
            <Setter Property="BorderBrush"      Value="#00b4d8"/>
            <Setter Property="BorderThickness"  Value="1"/>
            <Setter Property="Cursor"           Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1a4a7a"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- DataGrid row style -->
        <Style x:Key="DgRow" TargetType="DataGridRow">
            <Setter Property="Background"       Value="#16213e"/>
            <Setter Property="Foreground"       Value="#e0e0e0"/>
            <Setter Property="BorderThickness"  Value="0"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#1a4a7a"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#1e3a5f"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="240"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- ══ LEFT PANEL — Settings ══ -->
        <Border Grid.Column="0" Background="#16213e" Padding="16">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <!-- Logo / Title -->
                <TextBlock Text="⚔ Crystal Arbitrage" FontSize="16" FontWeight="Bold"
                           Foreground="#00b4d8" Margin="0,0,0,4"/>
                <TextBlock Text="Cross-World Market Scanner" FontSize="11"
                           Foreground="#888888" Margin="0,0,0,16"/>
                <Separator Background="#0f3460" Margin="0,0,0,8"/>

                <!-- Home World -->
                <TextBlock Text="HOME WORLD" Style="{StaticResource FieldLabel}"/>
                <ComboBox x:Name="CboHomeWorld" Style="{StaticResource FieldCombo}">
                    <ComboBoxItem>Balmung</ComboBoxItem>
                    <ComboBoxItem>Brynhildr</ComboBoxItem>
                    <ComboBoxItem IsSelected="True">Coeurl</ComboBoxItem>
                    <ComboBoxItem>Diabolos</ComboBoxItem>
                    <ComboBoxItem>Goblin</ComboBoxItem>
                    <ComboBoxItem>Malboro</ComboBoxItem>
                    <ComboBoxItem>Mateus</ComboBoxItem>
                    <ComboBoxItem>Zalera</ComboBoxItem>
                </ComboBox>

                <!-- Top Listing Count -->
                <TextBlock Text="TOP ITEMS TO ANALYSE" Style="{StaticResource FieldLabel}"/>
                <TextBox  x:Name="TxtTopCount" Text="2000" Style="{StaticResource FieldBox}"/>

                <!-- Min Profit Gil -->
                <TextBlock Text="MIN PROFIT / UNIT (GIL)" Style="{StaticResource FieldLabel}"/>
                <TextBox  x:Name="TxtMinProfit" Text="5000" Style="{StaticResource FieldBox}"/>

                <!-- Min Profit % -->
                <TextBlock Text="MIN PROFIT MARGIN %" Style="{StaticResource FieldLabel}"/>
                <TextBox  x:Name="TxtMinMargin" Text="20" Style="{StaticResource FieldBox}"/>

                <!-- Min Sales/Day -->
                <TextBlock Text="MIN SALES / DAY (HOME WORLD)" Style="{StaticResource FieldLabel}"/>
                <TextBox  x:Name="TxtMinSales" Text="5" Style="{StaticResource FieldBox}"/>

                <!-- Tax Rate -->
                <TextBlock Text="MARKET BOARD TAX %" Style="{StaticResource FieldLabel}"/>
                <TextBox  x:Name="TxtTaxRate" Text="5" Style="{StaticResource FieldBox}"/>

                <!-- Price Band -->
                <TextBlock Text="BUY PRICE BAND %" Style="{StaticResource FieldLabel}"/>
                <TextBox  x:Name="TxtPriceBand" Text="10" Style="{StaticResource FieldBox}"/>

                <!-- Min Units -->
                <TextBlock Text="MIN UNITS AVAILABLE" Style="{StaticResource FieldLabel}"/>
                <TextBox  x:Name="TxtMinUnits" Text="10" Style="{StaticResource FieldBox}"/>

                <Separator Background="#0f3460" Margin="0,16,0,8"/>

                <!-- Scan Button -->
                <Button x:Name="BtnScan" Content="▶  START SCAN"
                        Style="{StaticResource BtnPrimary}" Margin="0,4,0,4"/>

                <!-- Stop Button -->
                <Button x:Name="BtnStop" Content="■  STOP" IsEnabled="False"
                        Style="{StaticResource BtnSecondary}" Margin="0,0,0,4"/>

                <!-- Export Button -->
                <Button x:Name="BtnExport" Content="⬇  EXPORT CSV" IsEnabled="False"
                        Style="{StaticResource BtnSecondary}" Margin="0,0,0,16"/>

                <Separator Background="#0f3460" Margin="0,0,0,8"/>

                <!-- Stats panel -->
                <TextBlock x:Name="TxtStatItems"   Text="Items scanned: —"  Foreground="#888888" FontSize="11"/>
                <TextBlock x:Name="TxtStatDeals"   Text="Deals found: —"    Foreground="#888888" FontSize="11" Margin="0,2"/>
                <TextBlock x:Name="TxtStatElapsed" Text="Elapsed: —"        Foreground="#888888" FontSize="11"/>
            </StackPanel>
            </ScrollViewer>
        </Border>

        <!-- ══ RIGHT PANEL — Progress + Results ══ -->
        <Grid Grid.Column="1" Background="#1a1a2e">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Progress / Status bar -->
            <Border Grid.Row="0" Background="#16213e" Padding="12,8">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <TextBlock x:Name="TxtStatus" Grid.Row="0"
                               Text="Ready — configure settings and press Start Scan"
                               Foreground="#00b4d8" FontSize="13" FontWeight="SemiBold"/>
                    <ProgressBar x:Name="PrgScan" Grid.Row="1"
                                 Height="4" Margin="0,6,0,0"
                                 Background="#0f3460" Foreground="#00b4d8"
                                 BorderThickness="0"
                                 Value="0" Maximum="100"/>
                </Grid>
            </Border>

            <!-- Results DataGrid -->
            <DataGrid x:Name="DgResults" Grid.Row="1"
                      AutoGenerateColumns="False"
                      IsReadOnly="True"
                      CanUserSortColumns="True"
                      CanUserResizeColumns="True"
                      CanUserReorderColumns="True"
                      GridLinesVisibility="Horizontal"
                      HorizontalGridLinesBrush="#0f3460"
                      Background="#1a1a2e"
                      RowBackground="#16213e"
                      AlternatingRowBackground="#1a2040"
                      Foreground="#e0e0e0"
                      ColumnHeaderHeight="32"
                      RowHeight="26"
                      BorderThickness="0"
                      Margin="0,1,0,0"
                      RowStyle="{StaticResource DgRow}"
                      SelectionMode="Single"
                      SelectionUnit="FullRow">
                <DataGrid.ColumnHeaderStyle>
                    <Style TargetType="DataGridColumnHeader">
                        <Setter Property="Background"       Value="#0f3460"/>
                        <Setter Property="Foreground"       Value="#00b4d8"/>
                        <Setter Property="FontWeight"       Value="SemiBold"/>
                        <Setter Property="FontSize"         Value="11"/>
                        <Setter Property="Padding"          Value="8,0"/>
                        <Setter Property="BorderBrush"      Value="#1a1a2e"/>
                        <Setter Property="BorderThickness"  Value="0,0,1,0"/>
                    </Style>
                </DataGrid.ColumnHeaderStyle>
                <DataGrid.CellStyle>
                    <Style TargetType="DataGridCell">
                        <Setter Property="BorderThickness"  Value="0"/>
                        <Setter Property="Padding"          Value="8,0"/>
                        <Setter Property="Template">
                            <Setter.Value>
                                <ControlTemplate TargetType="DataGridCell">
                                    <Border Padding="{TemplateBinding Padding}"
                                            Background="{TemplateBinding Background}">
                                        <ContentPresenter VerticalAlignment="Center"/>
                                    </Border>
                                </ControlTemplate>
                            </Setter.Value>
                        </Setter>
                        <Style.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background"   Value="Transparent"/>
                                <Setter Property="Foreground"   Value="#e0e0e0"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </DataGrid.CellStyle>
                <DataGrid.Columns>
                    <DataGridTextColumn Header="#"          Binding="{Binding Rank}"           Width="40"  />
                    <DataGridTextColumn Header="Item Name"  Binding="{Binding ItemName}"        Width="200" />
                    <DataGridTextColumn Header="Buy On"     Binding="{Binding BuyWorld}"        Width="90"  />
                    <DataGridTextColumn Header="Buy Price"  Binding="{Binding BuyPriceFmt}"     Width="100" >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Units"      Binding="{Binding UnitsAvailable}"  Width="60"  >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Avg Sell"   Binding="{Binding AvgSellFmt}"      Width="100" >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Max Sell"   Binding="{Binding MaxSellFmt}"      Width="100" >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Avg Profit" Binding="{Binding AvgProfitFmt}"    Width="100" >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                                <Setter Property="Foreground"          Value="#2dc653"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Max Profit" Binding="{Binding MaxProfitFmt}"    Width="100" >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                                <Setter Property="Foreground"          Value="#e9c46a"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Avg Margin" Binding="{Binding AvgMarginFmt}"    Width="90"  >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Max Margin" Binding="{Binding MaxMarginFmt}"    Width="90"  >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Vol/Day"    Binding="{Binding VolPerDay}"       Width="75"  >
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="HorizontalAlignment" Value="Right"/>
                                <Setter Property="Padding" Value="0,0,8,0"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                </DataGrid.Columns>
            </DataGrid>
        </Grid>
    </Grid>
</Window>
'@

# ===========================================================================
# Load window from XAML
# ===========================================================================
$reader = [System.Xml.XmlNodeReader]::new($XAML)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Grab named controls
$cboHomeWorld  = $window.FindName('CboHomeWorld')
$txtTopCount   = $window.FindName('TxtTopCount')
$txtMinProfit  = $window.FindName('TxtMinProfit')
$txtMinMargin  = $window.FindName('TxtMinMargin')
$txtMinSales   = $window.FindName('TxtMinSales')
$txtTaxRate    = $window.FindName('TxtTaxRate')
$txtPriceBand  = $window.FindName('TxtPriceBand')
$txtMinUnits   = $window.FindName('TxtMinUnits')
$btnScan       = $window.FindName('BtnScan')
$btnStop       = $window.FindName('BtnStop')
$btnExport     = $window.FindName('BtnExport')
$dgResults     = $window.FindName('DgResults')
$txtStatus     = $window.FindName('TxtStatus')
$prgScan       = $window.FindName('PrgScan')
$txtStatItems  = $window.FindName('TxtStatItems')
$txtStatDeals  = $window.FindName('TxtStatDeals')
$txtStatElapsed= $window.FindName('TxtStatElapsed')

# Observable collection for the DataGrid
$dealRows = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$dgResults.ItemsSource = $dealRows

# Timer for elapsed display during scan
$elapsedTimer = [System.Windows.Threading.DispatcherTimer]::new()
$elapsedTimer.Interval = [TimeSpan]::FromSeconds(1)
$scanStart = $null

$elapsedTimer.Add_Tick({
    if ($null -ne $script:scanStart) {
        $elapsed = [math]::Round(([datetime]::Now - $script:scanStart).TotalSeconds)
        $txtStatElapsed.Text = "Elapsed: ${elapsed}s"
    }
})

# Job reference for the background scan
$script:scanJob   = $null
$script:lastDeals = $null

# ===========================================================================
# Helper: read and validate a numeric textbox
# ===========================================================================
function Read-Num {
    param([System.Windows.Controls.TextBox]$tb, [double]$min, [double]$max, [double]$default)
    $v = $default
    if ([double]::TryParse($tb.Text.Trim(), [ref]$v)) {
        if ($v -lt $min) { $v = $min }
        if ($v -gt $max) { $v = $max }
    }
    $tb.Text = $v
    return $v
}

# ===========================================================================
# The scan logic — runs as a background job so UI stays responsive
# ===========================================================================
$ScanScriptBlock = {
    param($HomeWorld, $TopListingCount, $MinProfitGil, $MinProfitPercent,
          $MinSalesPerDay, $TaxRate, $PriceBandPct, $MinUnitsAvailable)

    $BaseUrl    = 'https://universalis.app/api/v2'
    $Datacenter = 'Crystal'
    $BatchSize  = 100

    function Get-Prop {
        param($Obj, [string]$Name, $Default = $null)
        if ($null -eq $Obj) { return $Default }
        $p = $Obj.PSObject.Properties[$Name]
        if ($null -eq $p) { return $Default }
        return $p.Value
    }

    function Invoke-Api {
        param([string]$Url, [int]$Retries = 3)
        foreach ($attempt in 1..$Retries) {
            try { return Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 30 }
            catch {
                if ($attempt -lt $Retries) { Start-Sleep -Milliseconds (200 * $attempt) }
            }
        }
        return $null
    }

    function Split-IntoChunks {
        param([System.Collections.Generic.List[int]]$Source, [int]$Size)
        $out = [System.Collections.Generic.List[int[]]]::new()
        $i = 0
        while ($i -lt $Source.Count) {
            $end = [Math]::Min($i + $Size - 1, $Source.Count - 1)
            $out.Add([int[]]($Source[$i..$end]))
            $i += $Size
        }
        return $out
    }

    # --- Progress reporting via output stream ---
    function Send-Progress {
        param([string]$Stage, [string]$Message, [int]$Pct)
        [PSCustomObject]@{ Type='progress'; Stage=$Stage; Message=$Message; Pct=$Pct }
    }

    # ── Step 1: World list ────────────────────────────────────────────────
    Send-Progress 'worlds' 'Loading world list...' 2
    $worldsRaw     = Invoke-Api "$BaseUrl/worlds"
    $worldIdToName = @{}
    $homeWorldId   = $null
    foreach ($ww in $worldsRaw) {
        $wId = Get-Prop $ww 'id'; $wName = Get-Prop $ww 'name'
        if ($wId -is [System.Management.Automation.PSCustomObject]) { $wId = Get-Prop $wId 'id' }
        if ($null -ne $wId -and $wName) {
            try {
                $iid = [int]$wId
                $worldIdToName[$iid] = $wName
                if ($wName -eq $HomeWorld) { $homeWorldId = $iid }
            } catch {}
        }
    }

    # ── Step 2: Marketable items ──────────────────────────────────────────
    Send-Progress 'items' 'Loading all marketable items...' 5
    $itemIds = [System.Collections.Generic.List[int]]::new()
    $mRaw    = Invoke-Api "$BaseUrl/marketable"
    foreach ($id in @($mRaw)) { try { $itemIds.Add([int]$id) } catch {} }
    $totalItems = $itemIds.Count
    Send-Progress 'items' "Loaded $totalItems marketable items" 8

    $chunks = Split-IntoChunks -Source $itemIds -Size $BatchSize

    # ── Step 3: Item names (parallel) ────────────────────────────────────
    Send-Progress 'names' 'Resolving item names...' 10
    $nameResults = $chunks | ForEach-Object -ThrottleLimit 16 -Parallel {
        $rowsCsv = $_ -join ','
        $map = @{}
        $url = 'https://v2.xivapi.com/api/sheet/Item?fields=Name&rows=' + $rowsCsv
        foreach ($attempt in 1..3) {
            try {
                $resp = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 30
                $rows = $resp.PSObject.Properties['rows']?.Value
                if ($rows) {
                    foreach ($row in @($rows)) {
                        $rid  = $row.PSObject.Properties['row_id']?.Value
                        $name = $row.PSObject.Properties['fields']?.Value?.PSObject.Properties['Name']?.Value
                        if ($null -ne $rid -and $name) { $map["$rid"] = $name }
                    }
                    break
                }
            } catch { Start-Sleep -Milliseconds (200 * $attempt) }
        }
        # Garland Tools fallback for missing IDs
        foreach ($id in ($rowsCsv -split ',')) {
            if ($map.ContainsKey($id)) { continue }
            try {
                $gt   = Invoke-RestMethod -Uri ('https://www.garlandtools.org/db/doc/item/en/3/' + $id + '.json') -TimeoutSec 10
                $name = $gt.PSObject.Properties['item']?.Value?.PSObject.Properties['name']?.Value
                if ($name) { $map[$id] = $name }
            } catch {}
        }
        return $map
    }
    $itemNames = @{}
    foreach ($map in $nameResults) {
        if ($map -is [hashtable]) {
            foreach ($k in $map.Keys) {
                if ("$k" -match '^\d+$') { $itemNames[[int]$k] = $map[$k] }
            }
        }
    }
    Send-Progress 'names' "Resolved $($itemNames.Count) names" 20

    # ── Step 4a: Aggregated DC data (parallel) ────────────────────────────
    Send-Progress 'agg' "Fetching aggregated data ($($chunks.Count) batches)..." 22
    $aggResults = $chunks | ForEach-Object -ThrottleLimit 16 -Parallel {
        $idStr = $_ -join ','
        $url   = 'https://universalis.app/api/v2/aggregated/Crystal/' + $idStr
        foreach ($attempt in 1..3) {
            try {
                $raw = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 30
                $arr = $raw.PSObject.Properties['results']?.Value
                if ($arr) { return @($arr) }
                break
            } catch { Start-Sleep -Milliseconds (200 * $attempt) }
        }
        return @()
    }
    $aggData = @{}
    foreach ($batch in $aggResults) {
        foreach ($r in @($batch)) {
            $id = $r.PSObject.Properties['itemId']?.Value
            if ($null -ne $id -and "$id" -match '^\d+$') { $aggData[[int]$id] = $r }
        }
    }
    Send-Progress 'agg' "Received $($aggData.Count) aggregated records" 40

    # Sort by velocity, trim to TopListingCount
    $sortedIds = $itemIds | Sort-Object {
        $intId = [int]$_
        if ($aggData.ContainsKey($intId)) {
            $qty = $aggData[$intId].PSObject.Properties['nq']?.Value?.
                   PSObject.Properties['dailySaleVelocity']?.Value?.
                   PSObject.Properties['dc']?.Value?.
                   PSObject.Properties['quantity']?.Value
            if ($null -ne $qty) { -[double]$qty } else { 0 }
        } else { 0 }
    }
    $itemIds = [System.Collections.Generic.List[int]]::new()
    foreach ($sid in @($sortedIds) | Select-Object -First $TopListingCount) { $itemIds.Add([int]$sid) }
    $chunks  = Split-IntoChunks -Source $itemIds -Size $BatchSize
    Send-Progress 'agg' "Selected top $($itemIds.Count) items by velocity" 42

    # ── Step 4b: Home-world listings + history ────────────────────────────
    Send-Progress 'home' "Fetching $HomeWorld listings + history ($($chunks.Count) batches)..." 44
    $env:_ArbitrageHomeWorld  = $HomeWorld
    $env:_ArbitragePriceBand  = "$PriceBandPct"
    $jobHomeWorld = $HomeWorld
    $homeResults  = $chunks | ForEach-Object -ThrottleLimit 16 -Parallel {
        $baseUrl   = 'https://universalis.app/api/v2'
        $homeWorld = $env:_ArbitrageHomeWorld
        $idStr     = $_ -join ','
        $url       = $baseUrl + '/' + $homeWorld + '/' + $idStr + '?listings=20&entries=50'
        foreach ($attempt in 1..3) {
            try {
                $raw     = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 30
                $dataMap = @{}
                $itemsMap = $raw.PSObject.Properties['items']?.Value
                $targets  = if ($itemsMap) { $itemsMap.PSObject.Properties } else { $null }
                if (-not $targets -and $raw.PSObject.Properties['listings']) {
                    $targets = @([PSCustomObject]@{ Name = ($_ -join ',').Split(',')[0]; Value = $raw })
                }
                if ($targets) {
                    foreach ($prop in $targets) {
                        if ($prop.Name -notmatch '^\d+$') { continue }
                        $itemData = $prop.Value
                        $history  = $itemData.PSObject.Properties['recentHistory']?.Value
                        $listings = $itemData.PSObject.Properties['listings']?.Value
                        $avgPrice = $null; $maxPrice = 0L
                        if ($history) {
                            $nowMs  = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
                            $weekMs = 604800000L
                            $sales  = [System.Collections.Generic.List[PSObject]]::new()
                            foreach ($h in @($history)) {
                                if ($h.PSObject.Properties['hq']?.Value) { continue }
                                $sp = $h.PSObject.Properties['pricePerUnit']?.Value
                                $sq = $h.PSObject.Properties['quantity']?.Value
                                $st = $h.PSObject.Properties['timestamp']?.Value
                                if ($null -ne $sp) {
                                    $tsMs = if ($null -ne $st) { [long]$st * 1000L } else { $nowMs }
                                    $sales.Add([PSCustomObject]@{
                                        Price = [long]$sp
                                        Qty   = if ($null -ne $sq) { [int]$sq } else { 1 }
                                        Timestamp = $tsMs
                                    })
                                }
                            }
                            if ($sales.Count -gt 0) {
                                $sorted = @($sales | Sort-Object Price)
                                $n      = $sorted.Count
                                $trimN  = if ($n -gt 2) { [Math]::Max(1, [Math]::Floor($n * 0.10)) } else { 0 }
                                $loIdx  = $trimN; $hiIdx = $n - $trimN
                                if ($hiIdx -le $loIdx) { $hiIdx = $n; $loIdx = 0 }
                                $wSum = [double]0; $wCount = [double]0
                                for ($i = $loIdx; $i -lt $hiIdx; $i++) {
                                    $ageMs  = $nowMs - $sorted[$i].Timestamp
                                    $timeW  = [Math]::Max(0.1, 1.0 - ($ageMs / $weekMs * 0.9))
                                    $totalW = $timeW * $sorted[$i].Qty
                                    $wSum  += $sorted[$i].Price * $totalW
                                    $wCount += $totalW
                                }
                                if ($wCount -gt 0) { $avgPrice = [long]($wSum / $wCount) }
                                $maxPrice = [long]$sorted[$hiIdx - 1].Price
                            }
                        }
                        if ($null -eq $avgPrice -and $listings) {
                            $cheapPp = [long]::MaxValue
                            foreach ($lst in @($listings)) {
                                if ($lst.PSObject.Properties['hq']?.Value) { continue }
                                $pp = $lst.PSObject.Properties['pricePerUnit']?.Value
                                if ($null -ne $pp -and [long]$pp -lt $cheapPp) { $cheapPp = [long]$pp }
                            }
                            if ($cheapPp -ne [long]::MaxValue) { $avgPrice = $cheapPp; $maxPrice = $cheapPp }
                        }
                        if ($null -eq $avgPrice) { continue }
                        $salesPerDay = 0.0
                        if ($history) {
                            $weekAgoMs = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) - 604800000L
                            $cnt = 0
                            foreach ($h in @($history)) {
                                if ($h.PSObject.Properties['hq']?.Value) { continue }
                                $ts = $h.PSObject.Properties['timestamp']?.Value
                                if ($null -ne $ts -and ($ts * 1000) -gt $weekAgoMs) { $cnt++ }
                            }
                            $salesPerDay = [math]::Round($cnt / 7.0, 1)
                        }
                        $dataMap['avg:' + $prop.Name] = $avgPrice
                        $dataMap['max:' + $prop.Name] = $maxPrice
                        $dataMap['spd:' + $prop.Name] = $salesPerDay
                    }
                }
                return $dataMap
            } catch { Start-Sleep -Milliseconds (200 * $attempt) }
        }
        return @{}
    }
    $homeData = @{}
    foreach ($batch in $homeResults) {
        if ($batch -isnot [hashtable]) { continue }
        foreach ($k in $batch.Keys) {
            if ($k -match '^avg:(\d+)$') {
                $id = [int]$Matches[1]
                if (-not $homeData.ContainsKey($id)) { $homeData[$id] = @{ avgPrice=0L; maxPrice=0L; salesPerDay=0.0 } }
                $homeData[$id]['avgPrice'] = [long]$batch[$k]
            } elseif ($k -match '^max:(\d+)$') {
                $id = [int]$Matches[1]
                if (-not $homeData.ContainsKey($id)) { $homeData[$id] = @{ avgPrice=0L; maxPrice=0L; salesPerDay=0.0 } }
                $homeData[$id]['maxPrice'] = [long]$batch[$k]
            } elseif ($k -match '^spd:(\d+)$') {
                $id = [int]$Matches[1]
                if (-not $homeData.ContainsKey($id)) { $homeData[$id] = @{ avgPrice=0L; maxPrice=0L; salesPerDay=0.0 } }
                $homeData[$id]['salesPerDay'] = [double]$batch[$k]
            }
        }
    }
    $keysToRemove = @($homeData.Keys | Where-Object { $homeData[$_]['avgPrice'] -le 0 })
    foreach ($k in $keysToRemove) { $homeData.Remove($k) }
    Send-Progress 'home' "$($homeData.Count) home-world prices received" 62

    # ── Step 4c: Buy-world depth (pre-filtered) ───────────────────────────
    Send-Progress 'depth' 'Calculating profitable candidates...' 64
    $taxMultPre = 1.0 - ($TaxRate / 100.0)
    $worldItemMap = @{}
    foreach ($id in $itemIds) {
        if (-not $aggData.ContainsKey($id) -or -not $homeData.ContainsKey($id)) { continue }
        $nqData    = $aggData[$id].PSObject.Properties['nq']?.Value
        if (-not $nqData) { continue }
        $minListDc = $nqData.PSObject.Properties['minListing']?.Value?.PSObject.Properties['dc']?.Value
        $buyPrice  = [long]($minListDc.PSObject.Properties['price']?.Value ?? 0)
        $buyWId    = $minListDc.PSObject.Properties['worldId']?.Value
        if ($null -eq $buyWId -or $buyPrice -le 0) { continue }
        if ($buyWId -is [System.Management.Automation.PSCustomObject]) { $buyWId = $buyWId.PSObject.Properties['id']?.Value }
        $buyWIdInt = $null; try { $buyWIdInt = [int]$buyWId } catch { continue }
        $buyWName  = if ($worldIdToName.ContainsKey($buyWIdInt)) { $worldIdToName[$buyWIdInt] } else { $null }
        if (-not $buyWName -or $buyWName -eq $HomeWorld) { continue }
        $avgSell = $homeData[$id]['avgPrice']
        $netPre  = [long]([double]$avgSell * $taxMultPre)
        $profit  = $netPre - $buyPrice
        $margin  = if ($buyPrice -gt 0) { ($profit / [double]$buyPrice) * 100 } else { 0 }
        if ($profit -lt $MinProfitGil -or $margin -lt $MinProfitPercent) { continue }
        if (-not $worldItemMap.ContainsKey($buyWName)) { $worldItemMap[$buyWName] = [System.Collections.Generic.List[int]]::new() }
        $worldItemMap[$buyWName].Add($id)
    }
    $depthChunks = [System.Collections.Generic.List[PSObject]]::new()
    foreach ($wn in $worldItemMap.Keys) {
        $wc = [System.Collections.Generic.List[int]]::new($worldItemMap[$wn])
        $wChunks = Split-IntoChunks -Source $wc -Size $BatchSize
        foreach ($c in $wChunks) { $depthChunks.Add([PSCustomObject]@{ World=$wn; Ids=$c }) }
    }
    Send-Progress 'depth' "Fetching depth for $($depthChunks.Count) buy-world batches..." 66

    $jobPriceBandPct = $PriceBandPct
    $depthResults = $depthChunks | ForEach-Object -ThrottleLimit 16 -Parallel {
        $baseUrl      = 'https://universalis.app/api/v2'
        $worldName    = $_.World
        $idStr        = ($_.Ids | ForEach-Object { "$_" }) -join ','
        $priceBandPct = [int]$env:_ArbitragePriceBand
        $url          = $baseUrl + '/' + $worldName + '/' + $idStr + '?listings=50&entries=0'
        foreach ($attempt in 1..3) {
            try {
                $raw = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 30
                $depMap = @{}
                $itemsMap = $raw.PSObject.Properties['items']?.Value
                $targets  = if ($itemsMap) { $itemsMap.PSObject.Properties } else { $null }
                if (-not $targets -and $raw.PSObject.Properties['listings']) {
                    $targets = @([PSCustomObject]@{ Name=$idStr.Split(',')[0]; Value=$raw })
                }
                if ($targets) {
                    foreach ($prop in $targets) {
                        if ($prop.Name -notmatch '^\d+$') { continue }
                        $listings   = $prop.Value.PSObject.Properties['listings']?.Value
                        if (-not $listings) { $depMap[$prop.Name] = 0; continue }
                        $nqL = @($listings) | Where-Object { -not ($_.PSObject.Properties['hq']?.Value) }
                        if ($nqL.Count -eq 0) { $depMap[$prop.Name] = 0; continue }
                        $cheapest = [long]::MaxValue
                        foreach ($lst in $nqL) {
                            $pp = $lst.PSObject.Properties['pricePerUnit']?.Value
                            if ($null -ne $pp -and [long]$pp -lt $cheapest) { $cheapest = [long]$pp }
                        }
                        if ($cheapest -eq [long]::MaxValue) { $depMap[$prop.Name] = 0; continue }
                        $bandMax = $cheapest * (1.0 + $priceBandPct / 100.0)
                        $units = 0
                        foreach ($lst in $nqL) {
                            $pp = $lst.PSObject.Properties['pricePerUnit']?.Value
                            $qq = $lst.PSObject.Properties['quantity']?.Value
                            if ($null -ne $pp -and [long]$pp -le $bandMax -and $null -ne $qq) { $units += [int]$qq }
                        }
                        $depMap[$prop.Name] = $units
                    }
                }
                return $depMap
            } catch { Start-Sleep -Milliseconds (200 * $attempt) }
        }
        return @{}
    }
    $buyDepth = @{}
    foreach ($batch in $depthResults) {
        if ($batch -is [hashtable]) {
            foreach ($k in $batch.Keys) {
                if ("$k" -match '^\d+$') {
                    $id  = [int]$k
                    $ex  = if ($buyDepth.ContainsKey($id)) { $buyDepth[$id] } else { 0 }
                    $buyDepth[$id] = [Math]::Max($ex, [int]$batch[$k])
                }
            }
        }
    }
    Send-Progress 'depth' "Depth data: $($buyDepth.Count) items" 80

    # ── Step 5: Analysis ─────────────────────────────────────────────────
    Send-Progress 'analysis' 'Calculating arbitrage opportunities...' 82
    $taxMult  = 1.0 - ($TaxRate / 100.0)
    $dealsList = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($id in $itemIds) {
        if (-not $aggData.ContainsKey($id)) { continue }
        $nqData = $aggData[$id].PSObject.Properties['nq']?.Value
        if (-not $nqData) { continue }
        $minListDc  = $nqData.PSObject.Properties['minListing']?.Value?.PSObject.Properties['dc']?.Value
        $rawPrice   = $minListDc.PSObject.Properties['price']?.Value
        $buyWorldId = $minListDc.PSObject.Properties['worldId']?.Value
        $buyPrice   = $null; try { $buyPrice = [long]$rawPrice } catch { continue }
        if ($null -eq $buyPrice -or $buyPrice -le 0 -or $null -eq $buyWorldId) { continue }
        if ($buyWorldId -is [System.Management.Automation.PSCustomObject]) { $buyWorldId = $buyWorldId.PSObject.Properties['id']?.Value }
        $buyWorldIdInt = $null; try { $buyWorldIdInt = [int]$buyWorldId } catch { continue }
        $buyWorldName = if ($worldIdToName.ContainsKey($buyWorldIdInt)) { $worldIdToName[$buyWorldIdInt] } else { "World#$buyWorldIdInt" }
        if ($buyWorldName -eq $HomeWorld) { continue }
        if (-not $homeData.ContainsKey($id)) { continue }
        $hd = $homeData[$id]
        $avgSell = $null; $maxSell = $null
        try { $avgSell = [long]$hd['avgPrice']; $maxSell = [long]$hd['maxPrice'] } catch { continue }
        if ($null -eq $avgSell -or $avgSell -le 0) { continue }
        $netAvg = [long]([double]$avgSell * $taxMult)
        $netMax = [long]([double]$maxSell * $taxMult)
        $avgProfit = [long]($netAvg - $buyPrice)
        $maxProfit = [long]($netMax - $buyPrice)
        $avgPct = if ($buyPrice -gt 0) { [math]::Round(($avgProfit / $buyPrice) * 100, 1) } else { 0 }
        $maxPct = if ($buyPrice -gt 0) { [math]::Round(($maxProfit / $buyPrice) * 100, 1) } else { 0 }
        if ($avgProfit -lt $MinProfitGil -or $avgPct -lt $MinProfitPercent) { continue }
        $localSpd = if ($null -ne $hd['salesPerDay']) { [double]$hd['salesPerDay'] } else { 0.0 }
        if ($MinSalesPerDay -gt 0 -and $localSpd -lt $MinSalesPerDay) { continue }
        $units = if ($buyDepth.ContainsKey($id)) { $buyDepth[$id] } else { 0 }
        if ($units -lt $MinUnitsAvailable) { continue }
        $name = if ($itemNames.ContainsKey($id)) { $itemNames[$id] } else { "Item #$id" }
        $dealsList.Add([PSCustomObject]@{
            ItemID           = $id
            ItemName         = $name
            BuyWorld         = $buyWorldName
            BuyPrice         = $buyPrice
            UnitsAvailable   = $units
            AvgSellPrice     = $avgSell
            MaxSellPrice     = $maxSell
            NetAvgSell       = $netAvg
            NetMaxSell       = $netMax
            AvgProfit        = $avgProfit
            MaxProfit        = $maxProfit
            AvgProfitPct     = $avgPct
            MaxProfitPct     = $maxPct
            LocalSalesPerDay = $localSpd
        })
    }

    $sorted = @($dealsList | Where-Object {
        $_.AvgProfit -is [long] -and $_.BuyPrice -is [long]
    } | Sort-Object AvgProfit -Descending)

    Send-Progress 'done' "Found $($sorted.Count) opportunities" 100

    # Emit results
    $rank = 0
    foreach ($row in $sorted) {
        $rank++
        [PSCustomObject]@{
            Type           = 'result'
            Rank           = $rank
            ItemName       = $row.ItemName
            BuyWorld       = $row.BuyWorld
            BuyPrice       = $row.BuyPrice
            BuyPriceFmt    = $row.BuyPrice.ToString('N0')
            UnitsAvailable = $row.UnitsAvailable
            AvgSellFmt     = $row.NetAvgSell.ToString('N0')
            MaxSellFmt     = $row.NetMaxSell.ToString('N0')
            AvgProfitFmt   = $row.AvgProfit.ToString('N0')
            MaxProfitFmt   = $row.MaxProfit.ToString('N0')
            AvgMarginFmt   = "$($row.AvgProfitPct)%"
            MaxMarginFmt   = "$($row.MaxProfitPct)%"
            VolPerDay      = $row.LocalSalesPerDay
            AvgProfitPct   = $row.AvgProfitPct
            _raw           = $row
        }
    }
}

# ===========================================================================
# Timer to poll job results and update UI
# ===========================================================================
$pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
$pollTimer.Interval = [TimeSpan]::FromMilliseconds(250)

$pollTimer.Add_Tick({
    if ($null -eq $script:scanJob) { return }

    # Drain output
    $output = Receive-Job -Job $script:scanJob -ErrorAction SilentlyContinue
    foreach ($item in @($output)) {
        if ($null -eq $item) { continue }
        $t = $item.PSObject.Properties['Type']?.Value
        if ($t -eq 'progress') {
            $txtStatus.Text  = "[$($item.Stage)]  $($item.Message)"
            $prgScan.Value   = $item.Pct
            $txtStatItems.Text = "Items scanned: $($item.Message)"
        }
        elseif ($t -eq 'result') {
            $dealRows.Add($item)
            $txtStatDeals.Text = "Deals found: $($dealRows.Count)"
        }
    }

    # Check completion
    if ($script:scanJob.State -in 'Completed','Failed','Stopped') {
        $pollTimer.Stop()
        $elapsedTimer.Stop()
        $btnScan.IsEnabled   = $true
        $btnStop.IsEnabled   = $false
        $btnExport.IsEnabled = ($dealRows.Count -gt 0)
        $prgScan.Value       = 100
        $elapsed = [math]::Round(([datetime]::Now - $script:scanStart).TotalSeconds, 1)
        if ($script:scanJob.State -eq 'Failed') {
            $err = $script:scanJob.ChildJobs[0].JobStateInfo.Reason.Message
            $txtStatus.Text = "Scan failed: $err"
        } else {
            $txtStatus.Text = "Scan complete — $($dealRows.Count) opportunit$(if($dealRows.Count -eq 1){'y'}else{'ies'}) found in ${elapsed}s"
        }
        $txtStatElapsed.Text = "Elapsed: ${elapsed}s"
        Remove-Job -Job $script:scanJob -Force
        $script:scanJob = $null
    }
})

# ===========================================================================
# Button handlers
# ===========================================================================
$btnScan.Add_Click({
    # Validate inputs
    $hw  = $cboHomeWorld.SelectedItem.Content
    $tc  = [int](Read-Num $txtTopCount   10   2000 2000)
    $mg  = [int](Read-Num $txtMinProfit  0  9999999 5000)
    $mm  = [double](Read-Num $txtMinMargin  0  999 20)
    $ms  = [double](Read-Num $txtMinSales   0  999 5)
    $tr  = [int](Read-Num $txtTaxRate    0  5 5)
    $pb  = [int](Read-Num $txtPriceBand  0  50 10)
    $mu  = [int](Read-Num $txtMinUnits   1  9999 10)

    # Reset UI
    $dealRows.Clear()
    $btnScan.IsEnabled   = $false
    $btnStop.IsEnabled   = $true
    $btnExport.IsEnabled = $false
    $prgScan.Value       = 0
    $txtStatDeals.Text   = 'Deals found: —'
    $txtStatItems.Text   = 'Items scanned: —'
    $txtStatus.Text      = 'Starting scan...'

    $script:scanStart = [datetime]::Now
    $elapsedTimer.Start()

    $script:scanJob = Start-Job -ScriptBlock $ScanScriptBlock `
        -ArgumentList $hw,$tc,$mg,$mm,$ms,$tr,$pb,$mu

    $pollTimer.Start()
})

$btnStop.Add_Click({
    if ($null -ne $script:scanJob) {
        Stop-Job  -Job $script:scanJob
        Remove-Job -Job $script:scanJob -Force
        $script:scanJob = $null
    }
    $pollTimer.Stop()
    $elapsedTimer.Stop()
    $btnScan.IsEnabled = $true
    $btnStop.IsEnabled = $false
    $prgScan.Value     = 0
    $txtStatus.Text    = 'Scan stopped.'
})

$btnExport.Add_Click({
    $dlg = [Microsoft.Win32.SaveFileDialog]::new()
    $dlg.Filter   = 'CSV files (*.csv)|*.csv|All files (*.*)|*.*'
    $dlg.FileName = "crystal-arbitrage-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    if ($dlg.ShowDialog()) {
        $dealRows | ForEach-Object { $_._raw } |
            Export-Csv -Path $dlg.FileName -NoTypeInformation -Encoding UTF8
        $txtStatus.Text = "Exported $($dealRows.Count) rows to $($dlg.FileName)"
    }
})

# Colour rows by margin when they appear
$dgResults.Add_LoadingRow({
    param($sender, $e)
    $item = $e.Row.Item
    if ($null -eq $item) { return }
    $pct = $item.PSObject.Properties['AvgProfitPct']?.Value
    if ($null -eq $pct) { return }
    if ($pct -ge 100) {
        $e.Row.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.Color]::FromRgb(0x0a, 0x2e, 0x16)
    } elseif ($pct -ge 50) {
        $e.Row.Background = [System.Windows.Media.SolidColorBrush][System.Windows.Media.Color]::FromRgb(0x2e, 0x1e, 0x00)
    }
})

# Clean up on close
$window.Add_Closed({
    $pollTimer.Stop()
    $elapsedTimer.Stop()
    if ($null -ne $script:scanJob) {
        Stop-Job  -Job $script:scanJob -ErrorAction SilentlyContinue
        Remove-Job -Job $script:scanJob -Force -ErrorAction SilentlyContinue
    }
})

# Show window
$null = $window.ShowDialog()