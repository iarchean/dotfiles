import {
  ActionPanel,
  Action,
  List,
  Icon,
  Color,
  showToast,
  Toast,
  LocalStorage,
  Keyboard,
} from "@raycast/api";
import { useCachedPromise } from "@raycast/utils";
import { exec } from "child_process";
import { promisify } from "util";
import { existsSync } from "fs";
import { homedir } from "os";
import { useState, useMemo, useEffect, useCallback } from "react";

const execAsync = promisify(exec);

// Common gcloud installation paths
const GCLOUD_PATHS = [
  "/opt/homebrew/bin/gcloud",
  "/opt/homebrew/share/google-cloud-sdk/bin/gcloud",
  "/usr/local/bin/gcloud",
  "/usr/local/google-cloud-sdk/bin/gcloud",
  "/usr/bin/gcloud",
];

function findGcloudPath(): string | null {
  for (const path of GCLOUD_PATHS) {
    if (existsSync(path)) {
      return path;
    }
  }
  return null;
}

interface GCPProject {
  projectId: string;
  name: string;
}

interface ConsoleLink {
  title: string;
  path: string;
  icon: Icon;
  shortcut?: Keyboard.Shortcut;
}

interface ConsoleLinkGroup {
  title: string;
  links: ConsoleLink[];
}

// Organized GCP console links by category
const CONSOLE_LINK_GROUPS: ConsoleLinkGroup[] = [
  {
    title: "Compute",
    links: [
      { title: "Compute Engine (VMs)", path: "compute/instances", icon: Icon.Desktop, shortcut: { modifiers: ["cmd"], key: "v" } },
      { title: "Kubernetes Engine (GKE)", path: "kubernetes/list/overview", icon: Icon.Box, shortcut: { modifiers: ["cmd"], key: "g" } },
      { title: "Cloud Run", path: "run", icon: Icon.Globe, shortcut: { modifiers: ["cmd"], key: "r" } },
      { title: "Cloud Functions", path: "functions/list", icon: Icon.Code },
      { title: "App Engine", path: "appengine", icon: Icon.Window },
    ],
  },
  {
    title: "Storage & Database",
    links: [
      { title: "Cloud Storage", path: "storage/browser", icon: Icon.HardDrive, shortcut: { modifiers: ["cmd"], key: "s" } },
      { title: "BigQuery", path: "bigquery", icon: Icon.BarChart, shortcut: { modifiers: ["cmd"], key: "b" } },
      { title: "Cloud SQL", path: "sql/instances", icon: Icon.Coin },
      { title: "Firestore", path: "firestore/databases", icon: Icon.List },
      { title: "Memorystore (Redis)", path: "memorystore/redis/instances", icon: Icon.MemoryChip },
      { title: "Spanner", path: "spanner/instances", icon: Icon.Network },
    ],
  },
  {
    title: "Networking",
    links: [
      { title: "VPC Networks", path: "networking/networks/list", icon: Icon.Network },
      { title: "Load Balancing", path: "net-services/loadbalancing/list/loadBalancers", icon: Icon.Globe },
      { title: "Cloud DNS", path: "net-services/dns/zones", icon: Icon.Link },
      { title: "Cloud CDN", path: "net-services/cdn/list", icon: Icon.Globe },
      { title: "Cloud NAT", path: "net-services/nat/list", icon: Icon.ArrowRightCircle },
      { title: "Firewall Rules", path: "networking/firewalls/list", icon: Icon.Shield },
    ],
  },
  {
    title: "Observability",
    links: [
      { title: "Logging", path: "logs/query", icon: Icon.Document, shortcut: { modifiers: ["cmd"], key: "l" } },
      { title: "Monitoring", path: "monitoring", icon: Icon.LineChart, shortcut: { modifiers: ["cmd"], key: "m" } },
      { title: "Error Reporting", path: "errors", icon: Icon.ExclamationMark },
      { title: "Cloud Trace", path: "traces/list", icon: Icon.MagnifyingGlass },
      { title: "Cloud Profiler", path: "profiler", icon: Icon.Gauge },
      { title: "Uptime Checks", path: "monitoring/uptime", icon: Icon.Heartbeat },
    ],
  },
  {
    title: "Messaging & Integration",
    links: [
      { title: "Pub/Sub", path: "cloudpubsub/topic/list", icon: Icon.Message },
      { title: "Cloud Scheduler", path: "cloudscheduler", icon: Icon.Clock },
      { title: "Cloud Tasks", path: "cloudtasks", icon: Icon.CheckCircle },
      { title: "Eventarc", path: "eventarc/triggers", icon: Icon.Bolt },
      { title: "Workflows", path: "workflows", icon: Icon.Shuffle },
    ],
  },
  {
    title: "Security & IAM",
    links: [
      { title: "IAM", path: "iam-admin/iam", icon: Icon.Person, shortcut: { modifiers: ["cmd"], key: "i" } },
      { title: "Service Accounts", path: "iam-admin/serviceaccounts", icon: Icon.PersonCircle },
      { title: "Secret Manager", path: "security/secret-manager", icon: Icon.Key },
      { title: "Security Command Center", path: "security/command-center", icon: Icon.Shield },
      { title: "Identity-Aware Proxy", path: "security/iap", icon: Icon.Lock },
      { title: "Certificate Manager", path: "security/ccm/list/certificates", icon: Icon.Document },
    ],
  },
  {
    title: "CI/CD & Tools",
    links: [
      { title: "Cloud Build", path: "cloud-build/builds", icon: Icon.Hammer },
      { title: "Artifact Registry", path: "artifacts", icon: Icon.Box },
      { title: "Container Registry", path: "gcr/images", icon: Icon.Box },
      { title: "Cloud Deploy", path: "deploy/delivery-pipelines", icon: Icon.Upload },
      { title: "Source Repositories", path: "source/repos", icon: Icon.Code },
    ],
  },
  {
    title: "AI & ML",
    links: [
      { title: "Vertex AI", path: "vertex-ai", icon: Icon.Stars },
      { title: "AI Platform Models", path: "ai-platform/models", icon: Icon.LightBulb },
      { title: "Natural Language API", path: "natural-language", icon: Icon.SpeechBubble },
      { title: "Vision API", path: "vision", icon: Icon.Eye },
      { title: "Translation API", path: "translate", icon: Icon.Globe },
    ],
  },
  {
    title: "Management",
    links: [
      { title: "Dashboard", path: "home/dashboard", icon: Icon.House, shortcut: { modifiers: ["cmd"], key: "d" } },
      { title: "APIs & Services", path: "apis/dashboard", icon: Icon.Plug },
      { title: "Billing", path: "billing", icon: Icon.BankNote },
      { title: "Project Settings", path: "iam-admin/settings", icon: Icon.Gear },
      { title: "Quotas", path: "iam-admin/quotas", icon: Icon.Gauge },
      { title: "Labels", path: "resource-manager/labels", icon: Icon.Tag },
    ],
  },
];

// Flatten for quick access (first item from important groups)
const QUICK_LINKS: ConsoleLink[] = [
  { title: "Dashboard", path: "home/dashboard", icon: Icon.House, shortcut: { modifiers: ["cmd"], key: "d" } },
  { title: "Logging", path: "logs/query", icon: Icon.Document, shortcut: { modifiers: ["cmd"], key: "l" } },
  { title: "Compute Engine", path: "compute/instances", icon: Icon.Desktop, shortcut: { modifiers: ["cmd"], key: "v" } },
  { title: "GKE", path: "kubernetes/list/overview", icon: Icon.Box, shortcut: { modifiers: ["cmd"], key: "g" } },
  { title: "Cloud Run", path: "run", icon: Icon.Globe, shortcut: { modifiers: ["cmd"], key: "r" } },
  { title: "Cloud Storage", path: "storage/browser", icon: Icon.HardDrive, shortcut: { modifiers: ["cmd"], key: "s" } },
];

async function fetchGCPProjects(): Promise<GCPProject[]> {
  const gcloudPath = findGcloudPath();
  
  if (!gcloudPath) {
    throw new Error(
      "gcloud CLI not found. Please install Google Cloud SDK."
    );
  }

  const home = homedir();
  
  try {
    const { stdout } = await execAsync(
      `"${gcloudPath}" projects list --format="csv[no-heading](projectId,name)"`,
      { 
        timeout: 60000,
        shell: "/bin/bash",
        env: {
          HOME: home,
          PATH: `/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/share/google-cloud-sdk/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`,
          CLOUDSDK_CONFIG: `${home}/.gcloud`,
          CLOUDSDK_PYTHON: "/usr/bin/python3",
        },
      }
    );

    const projects: GCPProject[] = stdout
      .trim()
      .split("\n")
      .filter((line) => line.trim())
      .map((line) => {
        const [projectId, ...nameParts] = line.split(",");
        return {
          projectId: projectId.trim(),
          name: nameParts.join(",").trim() || projectId.trim(),
        };
      });

    return projects;
  } catch (error) {
    throw new Error(
      "Failed to fetch GCP projects. Make sure gcloud CLI is installed and authenticated."
    );
  }
}

function getProjectAccessories(projectId: string): List.Item.Accessory[] {
  const accessories: List.Item.Accessory[] = [];

  if (projectId.includes("-prod") || projectId.includes("-prd")) {
    accessories.push({ tag: { value: "PROD", color: Color.Red } });
  } else if (projectId.includes("-stg") || projectId.includes("-staging")) {
    accessories.push({ tag: { value: "STG", color: Color.Orange } });
  } else if (projectId.includes("-dev")) {
    accessories.push({ tag: { value: "DEV", color: Color.Green } });
  } else if (projectId.includes("-test") || projectId.includes("-qa")) {
    accessories.push({ tag: { value: "TEST", color: Color.Yellow } });
  }

  return accessories;
}

function buildConsoleUrl(projectId: string, path: string): string {
  return `https://console.cloud.google.com/${path}?project=${projectId}`;
}

// Recent projects storage
const RECENT_PROJECTS_KEY = "recentProjects";
const MAX_RECENT_PROJECTS = 10;

interface RecentProject {
  projectId: string;
  timestamp: number;
}

async function getRecentProjects(): Promise<string[]> {
  const stored = await LocalStorage.getItem<string>(RECENT_PROJECTS_KEY);
  if (!stored) return [];
  
  try {
    const recent: RecentProject[] = JSON.parse(stored);
    return recent
      .sort((a, b) => b.timestamp - a.timestamp)
      .map((r) => r.projectId);
  } catch {
    return [];
  }
}

async function addRecentProject(projectId: string): Promise<void> {
  const stored = await LocalStorage.getItem<string>(RECENT_PROJECTS_KEY);
  let recent: RecentProject[] = [];
  
  try {
    if (stored) {
      recent = JSON.parse(stored);
    }
  } catch {
    recent = [];
  }
  
  // Remove if already exists
  recent = recent.filter((r) => r.projectId !== projectId);
  
  // Add to front
  recent.unshift({ projectId, timestamp: Date.now() });
  
  // Keep only MAX_RECENT_PROJECTS
  recent = recent.slice(0, MAX_RECENT_PROJECTS);
  
  await LocalStorage.setItem(RECENT_PROJECTS_KEY, JSON.stringify(recent));
}

async function removeRecentProject(projectId: string): Promise<void> {
  const stored = await LocalStorage.getItem<string>(RECENT_PROJECTS_KEY);
  if (!stored) return;
  
  try {
    let recent: RecentProject[] = JSON.parse(stored);
    recent = recent.filter((r) => r.projectId !== projectId);
    await LocalStorage.setItem(RECENT_PROJECTS_KEY, JSON.stringify(recent));
  } catch {
    // ignore
  }
}

/**
 * Fuzzy match: checks if all search terms appear in the text (in any order)
 * Example: "gds s prod" matches "lkty-gds-s-prod"
 */
function fuzzyMatch(text: string, searchText: string): boolean {
  if (!searchText.trim()) return true;
  
  const lowerText = text.toLowerCase();
  const terms = searchText.toLowerCase().split(/\s+/).filter(Boolean);
  
  return terms.every((term) => lowerText.includes(term));
}

/**
 * Calculate match score for sorting (higher = better match)
 */
function getMatchScore(project: GCPProject, searchText: string): number {
  if (!searchText.trim()) return 0;
  
  const terms = searchText.toLowerCase().split(/\s+/).filter(Boolean);
  const projectId = project.projectId.toLowerCase();
  const name = project.name.toLowerCase();
  
  let score = 0;
  
  // Exact match bonus
  if (projectId === searchText.toLowerCase()) score += 1000;
  if (name === searchText.toLowerCase()) score += 1000;
  
  // Starts with first term bonus
  if (projectId.startsWith(terms[0])) score += 100;
  if (name.startsWith(terms[0])) score += 100;
  
  // Count matching terms
  for (const term of terms) {
    if (projectId.includes(term)) score += 10;
    if (name.includes(term)) score += 10;
  }
  
  return score;
}

export default function Command() {
  const [searchText, setSearchText] = useState("");
  const [recentProjectIds, setRecentProjectIds] = useState<string[]>([]);
  
  const { data: projects, isLoading, error, revalidate } = useCachedPromise(fetchGCPProjects, [], {
    keepPreviousData: true,
  });

  // Load recent projects on mount
  useEffect(() => {
    getRecentProjects().then(setRecentProjectIds);
  }, []);

  // Mark project as recently used
  const markAsRecent = useCallback(async (projectId: string) => {
    await addRecentProject(projectId);
    setRecentProjectIds(await getRecentProjects());
  }, []);

  // Remove from recent
  const removeFromRecent = useCallback(async (projectId: string) => {
    await removeRecentProject(projectId);
    setRecentProjectIds(await getRecentProjects());
  }, []);

  // Filter and sort projects based on fuzzy search
  const { recentProjects, otherProjects } = useMemo(() => {
    if (!projects) return { recentProjects: [], otherProjects: [] };
    
    const matched = projects.filter((project) => 
      fuzzyMatch(project.projectId, searchText) || 
      fuzzyMatch(project.name, searchText)
    );
    
    // Sort by match score (best matches first)
    const sorted = matched.sort((a, b) => 
      getMatchScore(b, searchText) - getMatchScore(a, searchText)
    );

    // Split into recent and other
    if (!searchText.trim()) {
      const recent = sorted.filter((p) => recentProjectIds.includes(p.projectId));
      const other = sorted.filter((p) => !recentProjectIds.includes(p.projectId));
      
      // Sort recent by recency
      recent.sort((a, b) => 
        recentProjectIds.indexOf(a.projectId) - recentProjectIds.indexOf(b.projectId)
      );
      
      return { recentProjects: recent, otherProjects: other };
    }
    
    return { recentProjects: [], otherProjects: sorted };
  }, [projects, searchText, recentProjectIds]);

  if (error) {
    showToast({
      style: Toast.Style.Failure,
      title: "Error",
      message: error.message,
    });
  }

  const renderProjectItem = (project: GCPProject, isRecent: boolean) => {
    const accessories = getProjectAccessories(project.projectId);
    return (
      <List.Item
        key={project.projectId}
        title={project.name || project.projectId}
        subtitle={project.projectId}
        accessories={accessories}
        icon={{ source: Icon.Cloud, tintColor: Color.Blue }}
        actions={
          <ActionPanel>
            {/* Quick Links - Most commonly used */}
            <ActionPanel.Section title="Quick Links">
              {QUICK_LINKS.map((link) => (
                <Action.OpenInBrowser
                  key={link.path}
                  title={link.title}
                  url={buildConsoleUrl(project.projectId, link.path)}
                  icon={link.icon}
                  shortcut={link.shortcut}
                  onOpen={() => markAsRecent(project.projectId)}
                />
              ))}
            </ActionPanel.Section>

            {/* Grouped Services */}
            {CONSOLE_LINK_GROUPS.map((group) => (
              <ActionPanel.Submenu
                key={group.title}
                title={group.title}
                icon={group.links[0].icon}
              >
                {group.links.map((link) => (
                  <Action.OpenInBrowser
                    key={link.path}
                    title={link.title}
                    url={buildConsoleUrl(project.projectId, link.path)}
                    icon={link.icon}
                    onOpen={() => markAsRecent(project.projectId)}
                  />
                ))}
              </ActionPanel.Submenu>
            ))}

            {/* Utility Actions */}
            <ActionPanel.Section title="Actions">
              <Action.CopyToClipboard
                title="Copy Project ID"
                content={project.projectId}
                shortcut={{ modifiers: ["cmd"], key: "c" }}
              />
              <Action.CopyToClipboard
                title="Copy Project Console URL"
                content={buildConsoleUrl(project.projectId, "home/dashboard")}
                shortcut={{ modifiers: ["cmd", "shift"], key: "c" }}
              />
              <Action.OpenInBrowser
                title="Open in Cloud Shell"
                url={`https://console.cloud.google.com/cloudshell/editor?project=${project.projectId}`}
                icon={Icon.Terminal}
                shortcut={{ modifiers: ["cmd"], key: "t" }}
                onOpen={() => markAsRecent(project.projectId)}
              />
              {isRecent && (
                <Action
                  title="Remove from Recent"
                  icon={Icon.Trash}
                  style={Action.Style.Destructive}
                  shortcut={{ modifiers: ["ctrl"], key: "x" }}
                  onAction={() => removeFromRecent(project.projectId)}
                />
              )}
              <Action
                title="Refresh Projects"
                icon={Icon.ArrowClockwise}
                shortcut={{ modifiers: ["cmd", "shift"], key: "r" }}
                onAction={revalidate}
              />
            </ActionPanel.Section>
          </ActionPanel>
        }
      />
    );
  };

  return (
    <List
      isLoading={isLoading}
      searchBarPlaceholder="Fuzzy search projects..."
      onSearchTextChange={setSearchText}
      filtering={false}
      throttle
    >
      {recentProjects.length > 0 && (
        <List.Section title="Recent" subtitle={`${recentProjects.length} projects`}>
          {recentProjects.map((project) => renderProjectItem(project, true))}
        </List.Section>
      )}
      <List.Section title={recentProjects.length > 0 ? "All Projects" : undefined}>
        {otherProjects.map((project) => renderProjectItem(project, false))}
      </List.Section>
    </List>
  );
}
