"use client"

import { useState } from "react"
import { SidebarNav } from "@/components/mockup/sidebar-nav"
import { PhotosSection } from "@/components/mockup/photos-section"
import { AlbumsSection } from "@/components/mockup/albums-section"
import { FavoritesSection } from "@/components/mockup/favorites-section"
import { SharedSection } from "@/components/mockup/shared-section"
import { UploadSection } from "@/components/mockup/upload-section"
import { UIKitSection } from "@/components/mockup/ui-kit-section"
import { Search } from "lucide-react"

const sectionMap: Record<string, React.ComponentType> = {
  photos: PhotosSection,
  albums: AlbumsSection,
  favorites: FavoritesSection,
  shared: SharedSection,
  upload: UploadSection,
}

export default function Page() {
  const [activeSection, setActiveSection] = useState("photos")

  const ActiveComponent = sectionMap[activeSection]

  return (
    <div className="flex min-h-screen bg-base-100">
      <SidebarNav onNavigate={setActiveSection} activeSection={activeSection} />

      <main className="flex-1 min-w-0 lg:ml-0">
        {/* Top bar */}
        <header className="sticky top-0 z-40 bg-base-100/90 backdrop-blur border-b border-base-300 px-4 sm:px-6 py-3 mt-[52px] lg:mt-0">
          <div className="flex items-center gap-3">
            <div className="form-control flex-1 max-w-sm">
              <label className="input input-sm input-bordered flex items-center gap-2 bg-base-200/60 border-base-300 rounded-md">
                <Search className="h-3.5 w-3.5 text-base-content/30" strokeWidth={1.5} />
                <input
                  type="text"
                  className="grow bg-transparent text-base-content placeholder:text-base-content/30 text-sm"
                  placeholder="Search photos, albums, tags..."
                />
              </label>
            </div>
            <span className="badge badge-sm badge-ghost text-base-content/40 font-mono text-[10px] tracking-wide hidden sm:inline-flex border-base-300">
              v1.0
            </span>
          </div>
        </header>

        {/* Content */}
        <div className="p-4 sm:p-6 lg:p-8 max-w-6xl">
          {ActiveComponent ? <ActiveComponent /> : null}

          {/* UI Kit reference */}
          <div className="mt-16 pt-8 border-t border-base-300">
            <p className="text-[10px] uppercase tracking-[0.2em] text-accent font-semibold font-mono mb-6">
              UI Kit Reference
            </p>
            <UIKitSection />
          </div>
        </div>
      </main>
    </div>
  )
}
