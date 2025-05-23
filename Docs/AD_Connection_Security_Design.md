# AD接続セキュリティ強化設計書

## 1. 目的
WinRMを利用したActive Directory接続のセキュリティ強化

## 2. 対象範囲
- [`Modules/UserManagement.ps1`](Modules/UserManagement.ps1)
- [`Core/Authentication.ps1`](Core/Authentication.ps1) 

## 3. 技術設計

### 3.1 暗号化設定
```powershell
# サーバ側設定 (既実施済み)
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $false
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $false
```

### 3.2 接続パラメータ
| パラメータ | 設定値 | 必須 |
|-----------|--------|------|
| UseSSL | $true | ○ |
| Authentication | Kerberos | ○ |
| Port | 5986 | ○ |

## 4. 変更影響
- 影響ファイル:
  - [`MainCliMenu.ps1`](MainCliMenu.ps1): 接続オプション追加
  - [`Docs/Operation_Guide.md`](Docs/Operation_Guide.md): 手順更新必要

## 5. テストケース
1. SSL接続テスト
2. 認証方式テスト
3. エラーハンドリングテスト