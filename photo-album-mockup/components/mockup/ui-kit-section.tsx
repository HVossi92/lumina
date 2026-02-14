import { AlertTriangle, CheckCircle2, Info, XCircle } from "lucide-react"

export function UIKitSection() {
  return (
    <section>
      <h2 className="text-3xl font-serif font-bold text-base-content mb-8 text-balance">UI Kit Reference</h2>

      {/* Buttons */}
      <Subsection title="Buttons">
        <div className="flex flex-wrap gap-3">
          <button className="btn btn-sm btn-primary rounded-md">Primary</button>
          <button className="btn btn-sm btn-secondary rounded-md">Secondary</button>
          <button className="btn btn-sm btn-accent rounded-md">Accent</button>
          <button className="btn btn-sm btn-ghost rounded-md">Ghost</button>
          <button className="btn btn-sm btn-outline rounded-md">Outline</button>
          <button className="btn btn-sm btn-neutral rounded-md">Neutral</button>
        </div>
        <div className="flex flex-wrap gap-3 mt-3">
          <button className="btn btn-xs btn-primary rounded-md">Extra Small</button>
          <button className="btn btn-sm btn-primary rounded-md">Small</button>
          <button className="btn btn-md btn-primary rounded-md">Medium</button>
          <button className="btn btn-lg btn-primary rounded-md">Large</button>
        </div>
        <div className="flex flex-wrap gap-3 mt-3">
          <button className="btn btn-sm btn-info rounded-md">Info</button>
          <button className="btn btn-sm btn-success rounded-md">Success</button>
          <button className="btn btn-sm btn-warning rounded-md">Warning</button>
          <button className="btn btn-sm btn-error rounded-md">Error</button>
        </div>
        <div className="flex flex-wrap gap-3 mt-3">
          <button className="btn btn-sm btn-primary rounded-md" disabled>Disabled</button>
          <button className="btn btn-sm btn-primary btn-outline rounded-md">Outline Primary</button>
          <button className="btn btn-sm btn-accent btn-outline rounded-md">Outline Accent</button>
        </div>
      </Subsection>

      {/* Badges */}
      <Subsection title="Badges">
        <div className="flex flex-wrap gap-2">
          <span className="badge badge-sm">Default</span>
          <span className="badge badge-sm badge-primary">Primary</span>
          <span className="badge badge-sm badge-secondary">Secondary</span>
          <span className="badge badge-sm badge-accent">Accent</span>
          <span className="badge badge-sm badge-info">Info</span>
          <span className="badge badge-sm badge-success">Success</span>
          <span className="badge badge-sm badge-warning">Warning</span>
          <span className="badge badge-sm badge-error">Error</span>
          <span className="badge badge-sm badge-outline">Outline</span>
          <span className="badge badge-md badge-accent">Medium</span>
          <span className="badge badge-lg badge-primary">Large</span>
        </div>
      </Subsection>

      {/* Alerts */}
      <Subsection title="Alerts">
        <div className="flex flex-col gap-3">
          <div className="alert alert-info rounded-md text-sm">
            <Info className="h-4 w-4 shrink-0" strokeWidth={1.5} />
            <span>Photos are automatically backed up to the cloud.</span>
          </div>
          <div className="alert alert-success rounded-md text-sm">
            <CheckCircle2 className="h-4 w-4 shrink-0" strokeWidth={1.5} />
            <span>Album created successfully. 24 photos added.</span>
          </div>
          <div className="alert alert-warning rounded-md text-sm">
            <AlertTriangle className="h-4 w-4 shrink-0" strokeWidth={1.5} />
            <span>Storage is 80% full. Consider upgrading your plan.</span>
          </div>
          <div className="alert alert-error rounded-md text-sm">
            <XCircle className="h-4 w-4 shrink-0" strokeWidth={1.5} />
            <span>Upload failed. File exceeds the 50MB size limit.</span>
          </div>
        </div>
      </Subsection>

      {/* Inputs */}
      <Subsection title="Form Inputs">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-2xl">
          <div className="form-control">
            <label className="label"><span className="label-text text-base-content text-sm">Text Input</span></label>
            <input type="text" placeholder="Enter text..." className="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full" />
          </div>
          <div className="form-control">
            <label className="label"><span className="label-text text-base-content text-sm">Select</span></label>
            <select className="select select-bordered select-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full">
              <option>Option A</option>
              <option>Option B</option>
            </select>
          </div>
          <div className="form-control">
            <label className="label"><span className="label-text text-base-content text-sm">Search (accent focus)</span></label>
            <input type="search" placeholder="Search..." className="input input-bordered input-sm input-accent bg-base-200/60 border-base-300 text-base-content rounded-md w-full" />
          </div>
          <div className="form-control">
            <label className="label"><span className="label-text text-base-content text-sm">Disabled</span></label>
            <input type="text" placeholder="Disabled..." className="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full" disabled />
          </div>
        </div>
      </Subsection>

      {/* Cards */}
      <Subsection title="Cards (Chelekom Variants)">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-base-200 border border-base-300 rounded-md p-4">
            <h3 className="text-sm font-semibold text-base-content mb-1">Default</h3>
            <p className="text-xs text-base-content/50 leading-relaxed">Standard card with subtle border. Clean and minimal.</p>
          </div>
          <div className="bg-base-200 shadow-lg rounded-md p-4">
            <h3 className="text-sm font-semibold text-base-content mb-1">Shadow</h3>
            <p className="text-xs text-base-content/50 leading-relaxed">Elevated card with prominent shadow for emphasis.</p>
          </div>
          <div className="bg-base-200 border-l-[3px] border-l-accent border border-base-300 rounded-md p-4">
            <h3 className="text-sm font-semibold text-base-content mb-1">Bordered</h3>
            <p className="text-xs text-base-content/50 leading-relaxed">Left accent border for callouts and highlights.</p>
          </div>
        </div>
      </Subsection>

      {/* Loading */}
      <Subsection title="Loading States">
        <div className="flex flex-wrap items-center gap-6">
          <span className="loading loading-spinner loading-md text-accent" />
          <span className="loading loading-dots loading-md text-accent" />
          <span className="loading loading-ring loading-md text-accent" />
          <span className="loading loading-bars loading-md text-accent" />
          <progress className="progress progress-accent w-48 h-1.5" value="40" max="100" />
        </div>
        <div className="mt-4 grid grid-cols-1 sm:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-base-200 rounded-md overflow-hidden border border-base-300">
              <div className="animate-pulse">
                <div className="bg-base-300 aspect-[4/3]" />
                <div className="p-3 flex flex-col gap-2">
                  <div className="bg-base-300 h-3 rounded w-3/4" />
                  <div className="bg-base-300 h-2.5 rounded w-1/2" />
                </div>
              </div>
            </div>
          ))}
        </div>
      </Subsection>

      {/* Controls */}
      <Subsection title="Controls">
        <div className="flex flex-wrap items-center gap-6">
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" className="checkbox checkbox-sm checkbox-accent rounded" defaultChecked />
            <span className="label-text text-base-content text-sm">Checkbox</span>
          </label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" className="toggle toggle-sm toggle-accent" defaultChecked />
            <span className="label-text text-base-content text-sm">Toggle</span>
          </label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="radio" name="radio-demo" className="radio radio-sm radio-accent" defaultChecked />
            <span className="label-text text-base-content text-sm">Radio A</span>
          </label>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="radio" name="radio-demo" className="radio radio-sm radio-accent" />
            <span className="label-text text-base-content text-sm">Radio B</span>
          </label>
        </div>
      </Subsection>

      {/* Overlays */}
      <Subsection title="Overlays">
        <div className="flex flex-wrap items-center gap-4">
          <div className="tooltip tooltip-accent" data-tip="This is a tooltip">
            <button className="btn btn-sm btn-outline rounded-md">Hover me (Tooltip)</button>
          </div>
          <button
            className="btn btn-sm btn-accent rounded-md"
            onClick={() => (document.getElementById("demo-modal") as HTMLDialogElement)?.showModal()}
          >
            Open Modal
          </button>
          <dialog id="demo-modal" className="modal">
            <div className="modal-box bg-base-100 rounded-md">
              <h3 className="font-serif font-bold text-lg text-base-content">Delete Photo?</h3>
              <p className="py-4 text-base-content/60 text-sm leading-relaxed">
                This action cannot be undone. The photo will be moved to trash for 30 days.
              </p>
              <div className="modal-action">
                <form method="dialog" className="flex gap-2">
                  <button className="btn btn-sm btn-ghost rounded-md">Cancel</button>
                  <button className="btn btn-sm btn-error rounded-md">Delete</button>
                </form>
              </div>
            </div>
            <form method="dialog" className="modal-backdrop">
              <button>close</button>
            </form>
          </dialog>
        </div>
      </Subsection>

      {/* Typography */}
      <Subsection title="Typography">
        <div className="max-w-lg flex flex-col gap-2">
          <h1 className="text-3xl font-serif font-bold text-base-content">Heading 1 (font-serif)</h1>
          <h2 className="text-2xl font-serif font-bold text-base-content">Heading 2</h2>
          <h3 className="text-xl font-serif font-semibold text-base-content">Heading 3</h3>
          <p className="text-base text-base-content/70 leading-relaxed">
            Body text with relaxed leading. Uses Source Sans for clean, readable paragraphs. The serif font (Playfair Display) is reserved for headings.
          </p>
          <p className="text-sm text-base-content/40">
            Caption / secondary text for dates, metadata, and helper info.
          </p>
          <code className="font-mono text-xs bg-base-300 text-accent px-2 py-1.5 rounded w-fit">
            font-mono: JetBrains Mono for code & EXIF
          </code>
        </div>
      </Subsection>

      {/* Color Palette */}
      <Subsection title="Color Palette">
        <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-3">
          <ColorSwatch name="primary" className="bg-primary text-primary-content" />
          <ColorSwatch name="secondary" className="bg-secondary text-secondary-content" />
          <ColorSwatch name="accent" className="bg-accent text-accent-content" />
          <ColorSwatch name="neutral" className="bg-neutral text-neutral-content" />
          <ColorSwatch name="base-100" className="bg-base-100 text-base-content border border-base-300" />
          <ColorSwatch name="base-200" className="bg-base-200 text-base-content border border-base-300" />
          <ColorSwatch name="base-300" className="bg-base-300 text-base-content" />
          <ColorSwatch name="info" className="bg-info text-base-100" />
          <ColorSwatch name="success" className="bg-success text-base-100" />
          <ColorSwatch name="warning" className="bg-warning text-neutral" />
          <ColorSwatch name="error" className="bg-error text-base-100" />
          <ColorSwatch name="content" className="bg-base-content text-base-100" />
        </div>
      </Subsection>
    </section>
  )
}

function Subsection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mb-10">
      <h3 className="text-[10px] uppercase tracking-[0.15em] text-base-content/40 font-semibold font-mono mb-4">{title}</h3>
      {children}
    </div>
  )
}

function ColorSwatch({ name, className }: { name: string; className: string }) {
  return (
    <div className={`rounded-md p-3 text-center ${className}`}>
      <p className="text-[10px] font-mono font-semibold">{name}</p>
    </div>
  )
}
