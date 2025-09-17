# PM2 Setup for PetCare Flutter Web App

This guide explains how to set up PM2 to manage your Flutter web application in production.

## Prerequisites

- Node.js (v14 or higher)
- Flutter SDK
- PM2 (installed globally)

## Installation

1. **Install PM2 globally:**
   ```bash
   npm install -g pm2
   ```

2. **Install project dependencies:**
   ```bash
   npm install
   ```

## Building the Flutter Web App

1. **Build the Flutter web app for production:**
   ```bash
   flutter build web --release
   ```

## PM2 Configuration

The project includes an `ecosystem.config.js` file that configures PM2 to run your Flutter web app.

### Configuration Details:
- **App Name:** petcare-web
- **Script:** server.js (Express.js server)
- **Port:** 3000
- **Environment:** production
- **Logs:** Stored in `./logs/` directory

## Running the Application

### Using PM2 Commands:

1. **Start the application:**
   ```bash
   pm2 start ecosystem.config.js
   ```

2. **Stop the application:**
   ```bash
   pm2 stop petcare-web
   ```

3. **Restart the application:**
   ```bash
   pm2 restart petcare-web
   ```

4. **Check status:**
   ```bash
   pm2 status
   ```

5. **View logs:**
   ```bash
   pm2 logs petcare-web
   ```

6. **Monitor in real-time:**
   ```bash
   pm2 monit
   ```

### Using the Management Script:

Run the `pm2-scripts.bat` file for an interactive menu:
```bash
pm2-scripts.bat
```

## Useful PM2 Commands

### Process Management:
- `pm2 list` - List all processes
- `pm2 show petcare-web` - Show detailed info about the app
- `pm2 delete petcare-web` - Delete the app from PM2
- `pm2 reload petcare-web` - Reload the app (zero-downtime)

### Logs:
- `pm2 logs petcare-web --lines 50` - Show last 50 lines
- `pm2 flush` - Clear all logs
- `pm2 logs --err` - Show only error logs

### Monitoring:
- `pm2 monit` - Real-time monitoring dashboard
- `pm2 status` - Quick status overview

## Auto-start on System Boot

To make PM2 start automatically when the system boots:

1. **Generate startup script:**
   ```bash
   pm2 startup
   ```

2. **Save current PM2 processes:**
   ```bash
   pm2 save
   ```

## Production Deployment

1. **Build the Flutter app:**
   ```bash
   flutter build web --release
   ```

2. **Start with PM2:**
   ```bash
   pm2 start ecosystem.config.js
   ```

3. **Save configuration:**
   ```bash
   pm2 save
   ```

4. **Set up auto-start:**
   ```bash
   pm2 startup
   ```

## Accessing the Application

Once running, your Flutter web app will be available at:
- **Local:** http://localhost:3000
- **Network:** http://[your-ip]:3000

## Troubleshooting

### Common Issues:

1. **Port already in use:**
   - Change the PORT in `ecosystem.config.js`
   - Or kill the process using the port

2. **Build files not found:**
   - Make sure to run `flutter build web --release` first
   - Check that `build/web` directory exists

3. **PM2 process keeps restarting:**
   - Check logs: `pm2 logs petcare-web`
   - Verify the server.js file is correct

### Logs Location:
- Error logs: `./logs/err.log`
- Output logs: `./logs/out.log`
- Combined logs: `./logs/combined.log`

## File Structure

```
petcare/
├── build/web/           # Flutter web build output
├── logs/               # PM2 log files
├── server.js           # Express.js server
├── ecosystem.config.js # PM2 configuration
├── pm2-scripts.bat     # Management script
└── PM2-SETUP.md        # This file
```

## Environment Variables

You can customize the following environment variables in `ecosystem.config.js`:
- `NODE_ENV`: Set to 'production'
- `PORT`: Server port (default: 3000)

## Security Considerations

For production deployment:
1. Use a reverse proxy (nginx) in front of PM2
2. Set up SSL/TLS certificates
3. Configure firewall rules
4. Monitor logs regularly
5. Set up log rotation

## Support

If you encounter any issues:
1. Check the PM2 logs
2. Verify the Flutter build
3. Ensure all dependencies are installed
4. Check port availability
