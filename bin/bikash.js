#!/usr/bin/env node

const { program } = require('commander');
const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');
const axios = require('axios');
const { execSync } = require('child_process');
const os = require('os');
const tar = require('tar');

const PACKAGE_NAME = 'bikash-ai';
const CURRENT_VERSION = require('../package.json').version;
const GITHUB_REPO = 'your-username/bikash-ai'; // CHANGE THIS!

// --- Helper Functions for Cross-Platform Compatibility ---

function getInstallDir() {
    const homeDir = os.homedir();
    if (process.platform === 'win32') {
        // Windows: Use AppData
        return path.join(process.env.APPDATA, PACKAGE_NAME);
    } else {
        // macOS/Linux: Use a hidden directory in home
        return path.join(homeDir, `.${PACKAGE_NAME}`);
    }
}

function getBinDir() {
    const homeDir = os.homedir();
    if (process.platform === 'win32') {
        return path.join(homeDir, '.local', 'bin');
    } else {
        return path.join(homeDir, '.local', 'bin');
    }
}

// --- CLI Commands ---

program
    .name('bikash')
    .description(chalk.cyan('Bikash-AI: Your Personal AI-Powered Development Agent'))
    .version(CURRENT_VERSION);

program
    .command('init')
    .description('Initialize Bikash-AI in the current directory')
    .action(() => {
        console.log(chalk.green('✨ Initializing Bikash-AI...'));
        
        const cwd = process.cwd();
        const configPath = path.join(cwd, '.bikash');
        
        // Create a .bikash config directory in the user's project
        if (!fs.existsSync(configPath)) {
            fs.mkdirSync(configPath);
            console.log(chalk.gray(`Created ${configPath}`));
        }

        // Create a sample config file
        const configFile = path.join(configPath, 'config.json');
        const defaultConfig = {
            version: CURRENT_VERSION,
            projectName: path.basename(cwd),
            createdAt: new Date().toISOString(),
            mcpServer: {
                type: 'remote',
                // This is the URL to the MCP server running on your ASUS server
                url: 'http://<asus-tailscale-ip>:3000/sse'
            }
        };

        if (!fs.existsSync(configFile)) {
            fs.writeJsonSync(configFile, defaultConfig, { spaces: 2 });
            console.log(chalk.green(`Created default config at ${configFile}`));
        } else {
            console.log(chalk.yellow(`Config already exists at ${configFile}`));
        }

        console.log(chalk.green('✅ Bikash-AI is ready!'));
        console.log(chalk.gray('   Edit .bikash/config.json to connect to your ASUS server.'));
    });

program
    .command('update')
    .description('Check for and install the latest version of Bikash-AI')
    .action(async () => {
        console.log(chalk.cyan(`🔍 Checking for updates... (Current: v${CURRENT_VERSION})`));
        try {
            // Fetch the latest release from GitHub
            const response = await axios.get(`https://api.github.com/repos/${GITHUB_REPO}/releases/latest`);
            const latestVersion = response.data.tag_name.replace('v', '');
            
            if (latestVersion === CURRENT_VERSION) {
                console.log(chalk.green('✨ You are already on the latest version!'));
                return;
            }

            console.log(chalk.yellow(`🚀 New version found: v${latestVersion}`));
            console.log(chalk.gray('   Downloading and installing update...'));

            // Determine the correct asset for the user's OS and architecture
            const platform = os.platform();
            const arch = os.arch();
            let assetPattern;
            if (platform === 'win32') assetPattern = 'win';
            else if (platform === 'darwin') assetPattern = 'macos';
            else assetPattern = 'linux';
            if (arch === 'x64') assetPattern += '-x64';
            else if (arch === 'arm64') assetPattern += '-arm64';

            const asset = response.data.assets.find(a => a.name.includes(assetPattern));
            if (!asset) {
                throw new Error(`No compatible binary found for ${platform}-${arch}`);
            }

            // Download and extract the update
            const downloadPath = path.join(os.tmpdir(), asset.name);
            const writer = fs.createWriteStream(downloadPath);
            const downloadResponse = await axios({ url: asset.browser_download_url, method: 'GET', responseType: 'stream' });
            downloadResponse.data.pipe(writer);

            await new Promise((resolve, reject) => {
                writer.on('finish', resolve);
                writer.on('error', reject);
            });

            // Extract to the installation directory
            const installDir = getInstallDir();
            await tar.x({ file: downloadPath, C: installDir });
            fs.unlinkSync(downloadPath); // Clean up

            console.log(chalk.green(`✅ Successfully updated to v${latestVersion}!`));
            console.log(chalk.gray('   Please restart your terminal or run `bikash --version` to verify.'));
        } catch (error) {
            console.error(chalk.red(`❌ Update failed: ${error.message}`));
            process.exit(1);
        }
    });

// --- Handle Unknown Commands ---
program.on('command:*', function (operands) {
    console.error(chalk.red(`❌ Error: Invalid command '${operands[0]}'`));
    console.log(chalk.gray(`See '${PACKAGE_NAME} --help' for a list of available commands.`));
    process.exit(1);
});

program.parse(process.argv);
